#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "optparse"
require "rbconfig"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
GENERATOR = File.join(ROOT, "scripts", "generate_claude_md.rb")
PROJECT_AGENT_GENERATOR = File.join(ROOT, "scripts", "generate_project_agents.rb")
GENERATED_ARTIFACT = File.join(ROOT, "GENERATED_CLAUDE.md")
VERSION_FILES = {
  "PRODUCT_OVERVIEW.md" => File.join(ROOT, "PRODUCT_OVERVIEW.md"),
  "ARCHITECTURE.md" => File.join(ROOT, "ARCHITECTURE.md")
}.freeze
CHANGELOG = File.join(ROOT, "CHANGELOG.md")

class RuleVerifier
  def initialize(expected_version: nil)
    @expected_version = normalize_version(expected_version)
    @checks = []
  end

  def run
    catalog = generator_catalog
    verify_hard_constraints(catalog.fetch("docs"))
    verify_required_docs(catalog)
    verify_generated_artifact
    verify_project_agent_generator
    verify_versions
    verify_nested_agents

    {
      passed: @checks.all? { |check| check.fetch(:passed) },
      expected_version: @expected_version,
      checks: @checks
    }
  end

  private

  def verify_hard_constraints(docs)
    missing = docs.each_with_object([]) do |doc, result|
      path = File.join(ROOT, doc.fetch("file"))
      result << doc.fetch("file") unless File.read(path, encoding: "UTF-8").match?(/^## 硬约束$/)
    end
    record("主题文档硬约束", missing.empty?, missing.empty? ? "全部主题文档均包含“硬约束”章节。" : "缺少章节：#{missing.join(', ')}")
  end

  def verify_required_docs(catalog)
    required_files = catalog.fetch("docs").select { |doc| doc.fetch("tags").include?("required") }.map { |doc| doc.fetch("file") }
    missing = catalog.fetch("profiles").flat_map do |name, profile|
      output = generator_output("--profile", name, "--compact", "--dry-run")
      required_files.reject { |file| output.include?("`#{file}`") }.map { |file| "#{name}: #{file}" }
    end
    record("必选规则覆盖", missing.empty?, missing.empty? ? "所有项目画像都会整合必选规则。" : "缺少必选规则：#{missing.join(', ')}")
  end

  def verify_generated_artifact
    Dir.mktmpdir("agentrules-verify") do |dir|
      expected = File.join(dir, "GENERATED_CLAUDE.md")
      generator_output("--all", "--compact", "--output", expected, "--force")
      generated = File.exist?(GENERATED_ARTIFACT) && File.binread(GENERATED_ARTIFACT) == File.binread(expected)
      header = generated && File.read(GENERATED_ARTIFACT, encoding: "UTF-8").start_with?("<!-- GENERATED FILE — DO NOT EDIT.")
      record("生成产物同步", generated && header, generated && header ? "GENERATED_CLAUDE.md 与生成器一致，且标明不可直接编辑。" : "请重新生成 GENERATED_CLAUDE.md，且保留生成文件标记。")
    end
  end

  def verify_project_agent_generator
    Dir.mktmpdir("agentrules-project") do |dir|
      create_project_fixture(dir)
      first = project_generator_output(dir)
      generated_paths = %w[AGENTS.md apps/web/AGENTS.md services/api/AGENTS.md .github/AGENTS.md]
      generated = generated_paths.all? { |path| File.exist?(File.join(dir, path)) }
      parent_chain = nested_fixture_agents(dir).all? { |path| File.read(path, encoding: "UTF-8").include?("> **Parent:**") }
      web_agent = File.read(File.join(dir, "apps", "web", "AGENTS.md"), encoding: "UTF-8")
      package_manager_ok = web_agent.include?("`npm ci`") && web_agent.include?("`npm run test`")
      root_before = File.binread(File.join(dir, "AGENTS.md"))
      second = project_generator_output(dir)
      preserved = File.binread(File.join(dir, "AGENTS.md")) == root_before
      skipped = second.fetch("actions").all? { |action| action.fetch("status") == "skipped" }
      template_ok = first.fetch("template") == "go-react-embed"
      passed = generated && parent_chain && package_manager_ok && preserved && skipped && template_ok
      record("项目 AGENTS 脚手架", passed, project_generator_detail(passed))
    end
  end

  def create_project_fixture(dir)
    FileUtils.mkdir_p(File.join(dir, "apps", "web"))
    FileUtils.mkdir_p(File.join(dir, "services", "api"))
    FileUtils.mkdir_p(File.join(dir, ".github", "workflows"))
    package = { name: "fixture", private: true, scripts: { lint: "eslint .", test: "vitest run", build: "vite build" } }
    File.write(File.join(dir, "package-lock.json"), "{}\n", encoding: "UTF-8")
    File.write(File.join(dir, "apps", "web", "package.json"), "#{JSON.pretty_generate(package)}\n", encoding: "UTF-8")
    File.write(File.join(dir, "services", "api", "go.mod"), "module example.test/api\n\ngo 1.24\n", encoding: "UTF-8")
  end

  def project_generator_output(dir)
    output, status = Open3.capture2e(
      RbConfig.ruby,
      PROJECT_AGENT_GENERATOR,
      "--target",
      dir
    )
    raise "项目 AGENTS 生成器执行失败：#{output}" unless status.success?

    JSON.parse(output)
  end

  def nested_fixture_agents(dir)
    Dir.glob(File.join(dir, "**", "AGENTS.md")).reject { |path| path == File.join(dir, "AGENTS.md") }
  end

  def project_generator_detail(passed)
    return "分层生成、模板选择、锁文件适配、Parent 上溯链与禁止覆盖均通过。" if passed

    "项目脚手架行为异常：请检查首次生成、锁文件适配、Parent 链接和重复执行保护。"
  end

  def verify_versions
    versions = VERSION_FILES.transform_values { |path| extract_version(path) }
    versions["CHANGELOG.md"] = extract_changelog_version
    expected_matches = @expected_version.nil? || versions.values.all? { |version| version == @expected_version }
    consistent = versions.values.uniq.size == 1
    passed = consistent && expected_matches
    detail = if passed
      "版本一致：#{versions.values.first}。"
    elsif !consistent
      "版本不一致：#{versions.map { |file, version| "#{file}=#{version || '缺失'}" }.join(', ')}"
    else
      "版本应为 #{@expected_version}，实际为 #{versions.values.first || '缺失'}。"
    end
    record("版本与变更记录", passed, detail)
  end

  def verify_nested_agents
    nested = Dir.glob(File.join(ROOT, "**", "AGENTS.md")).reject { |path| path == File.join(ROOT, "AGENTS.md") }
    missing = nested.reject do |path|
      File.read(path, encoding: "UTF-8").match?(/^> \*\*Parent:\*\*/)
    end.map { |path| path.delete_prefix("#{ROOT}/") }
    record("嵌套 AGENTS 上溯链", missing.empty?, missing.empty? ? "没有缺失父级链接的嵌套 AGENTS.md。" : "缺少 Parent 链接：#{missing.join(', ')}")
  end

  def generator_catalog
    JSON.parse(generator_output("--catalog-json"))
  end

  def generator_output(*args)
    output, status = Open3.capture2e(RbConfig.ruby, GENERATOR, *args)
    return output if status.success?

    raise "生成器执行失败：#{output}"
  end

  def extract_version(path)
    File.read(path, encoding: "UTF-8")[/当前版本：v([0-9]+\.[0-9]+\.[0-9]+(?:-rc\d+)?)/, 1]
  end

  def extract_changelog_version
    File.read(CHANGELOG, encoding: "UTF-8")[/^## \[([0-9]+\.[0-9]+\.[0-9]+(?:-rc\d+)?)\]/, 1]
  end

  def normalize_version(value)
    value&.sub(/\Av/, "")
  end

  def record(name, passed, detail)
    @checks << { name: name, passed: passed, detail: detail }
  end
end

def parse_options(argv)
  options = {
    expected_version: nil,
    json_output: "tmp/rule-verification.json",
    markdown_output: "tmp/rule-verification.md"
  }

  OptionParser.new do |opts|
    opts.banner = "用法：ruby scripts/verify_rules.rb [options]"
    opts.on("--expected-version VERSION", "要求 Product Overview、Architecture 和 Changelog 使用该版本") { |value| options[:expected_version] = value }
    opts.on("--json-output PATH", "JSON 报告路径") { |value| options[:json_output] = value }
    opts.on("--markdown-output PATH", "Markdown 报告路径") { |value| options[:markdown_output] = value }
  end.parse!(argv)
  options
end

def report_path(path)
  File.expand_path(path, ROOT)
end

def write_report(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
end

def markdown_report(result)
  status = result.fetch(:passed) ? "PASS" : "FAIL"
  lines = ["# Rule Verification Report", "", "> Result: #{status}"]
  lines << "> Expected version: v#{result.fetch(:expected_version)}" if result.fetch(:expected_version)
  lines << "" << "| 检查项 | 结果 | 说明 |" << "|--------|------|------|"
  result.fetch(:checks).each do |check|
    lines << "| #{check.fetch(:name)} | #{check.fetch(:passed) ? 'PASS' : 'FAIL'} | #{check.fetch(:detail)} |"
  end
  "#{lines.join("\n")}\n"
end

options = parse_options(ARGV)
result = RuleVerifier.new(expected_version: options.fetch(:expected_version)).run
write_report(report_path(options.fetch(:json_output)), "#{JSON.pretty_generate(result)}\n")
write_report(report_path(options.fetch(:markdown_output)), markdown_report(result))
puts "规则校验：#{result.fetch(:passed) ? '通过' : '失败'}"
exit(result.fetch(:passed) ? 0 : 1)
