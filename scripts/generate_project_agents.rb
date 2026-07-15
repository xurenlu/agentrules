#!/usr/bin/env ruby
# frozen_string_literal: true

require "erb"
require "fileutils"
require "json"
require "open3"
require "optparse"
require "pathname"
require "rbconfig"

ROOT = File.expand_path("..", __dir__)
RULE_GENERATOR = File.join(ROOT, "scripts", "generate_claude_md.rb")
ROOT_TEMPLATE = File.join(ROOT, "templates", "agents", "root.md.erb")
NESTED_TEMPLATE = File.join(ROOT, "templates", "agents", "nested.md.erb")
MANIFESTS = %w[package.json go.mod pyproject.toml Cargo.toml Gemfile].freeze
IGNORED_DIRECTORIES = %w[.git node_modules vendor dist build target .venv venv tmp].freeze
TEMPLATE_PROFILES = {
  "generic" => "generic",
  "react-web" => "desktop-web",
  "go-api" => "go-api",
  "go-react-embed" => "go-react-embed"
}.freeze

class ProjectAgentGenerator
  def initialize(target:, template_name:, max_depth:, dry_run:)
    @target = File.expand_path(target)
    raise ArgumentError, "目标项目目录不存在：#{@target}" unless Dir.exist?(@target)

    @max_depth = max_depth
    @template_name = template_name == "auto" ? detect_template : template_name
    @dry_run = dry_run
    @actions = []
  end

  def run
    directories = [@target] + discover_module_directories
    directories.each_with_index do |directory, index|
      create_agent(directory, index.zero?, directories)
    end
    { passed: true, target: @target, template: @template_name, dry_run: @dry_run, actions: @actions }
  end

  private

  def discover_module_directories
    manifest_dirs = Dir.glob(File.join(@target, "**", "{#{MANIFESTS.join(',')}}")).map { |path| File.dirname(path) }
    special_dirs = []
    special_dirs << File.join(@target, ".github") if Dir.exist?(File.join(@target, ".github", "workflows"))
    special_dirs << File.join(@target, "tests") if Dir.exist?(File.join(@target, "tests"))
    (manifest_dirs + special_dirs).uniq.select { |dir| pertinent_directory?(dir) }.sort_by { |dir| [path_depth(dir), dir] }
  end

  def pertinent_directory?(directory)
    return false if directory == @target

    relative = relative_path(directory)
    segments = relative.split(File::SEPARATOR)
    segments.none? { |segment| IGNORED_DIRECTORIES.include?(segment) } && path_depth(directory) <= @max_depth
  end

  def create_agent(directory, root_agent, directories)
    agent_path = File.join(directory, "AGENTS.md")
    if File.exist?(agent_path)
      @actions << action(agent_path, "skipped", "文件已存在，未覆盖。")
      return
    end

    content = root_agent ? render_root(directory) : render_nested(directory, directories)
    status = @dry_run ? "planned" : "created"
    unless @dry_run
      FileUtils.mkdir_p(directory)
      File.write(agent_path, content, encoding: "UTF-8")
    end
    @actions << action(agent_path, status, "使用 #{@template_name} 模板。")
  end

  def render_root(directory)
    context = {
      project_name: File.basename(directory),
      template_name: @template_name,
      commands_markdown: markdown_list(commands_for(directory)),
      rules_fragment: rules_fragment
    }
    render_template(ROOT_TEMPLATE, context)
  end

  def render_nested(directory, directories)
    agent_path = File.join(directory, "AGENTS.md")
    parent_agent = File.join(nearest_parent_directory(directory, directories), "AGENTS.md")
    context = {
      module_name: File.basename(directory),
      scope: relative_path(directory),
      parent_label: relative_path(parent_agent),
      parent_link: Pathname.new(parent_agent).relative_path_from(Pathname.new(directory)).to_s,
      manifests_markdown: manifests_markdown(directory),
      commands_markdown: markdown_list(commands_for(directory)),
      module_rules_markdown: markdown_list(module_rules(directory))
    }
    render_template(NESTED_TEMPLATE, context)
  end

  def nearest_parent_directory(directory, directories)
    candidates = directories.select { |candidate| candidate != directory && directory.start_with?("#{candidate}#{File::SEPARATOR}") }
    candidates.max_by { |candidate| path_depth(candidate) } || @target
  end

  def commands_for(directory)
    commands = []
    commands.concat(package_commands(directory)) if File.exist?(File.join(directory, "package.json"))
    commands.concat(["运行 Go 测试：`go test ./...`", "检查 Go 构建：`go build ./...`"]) if File.exist?(File.join(directory, "go.mod"))
    commands.concat(["运行 Python 测试：`pytest`", "检查 Python 代码：`ruff check .`"]) if File.exist?(File.join(directory, "pyproject.toml"))
    commands.concat(["运行 Rust 测试：`cargo test`", "检查 Rust 代码：`cargo check`"]) if File.exist?(File.join(directory, "Cargo.toml"))
    commands << "按根目录规则运行相关测试；不要凭空猜测命令。" if commands.empty?
    commands
  end

  def package_commands(directory)
    package = JSON.parse(File.read(File.join(directory, "package.json"), encoding: "UTF-8"))
    scripts = package.is_a?(Hash) && package["scripts"].is_a?(Hash) ? package.fetch("scripts") : {}
    manager = package_manager_for(directory)
    install = manager == "npm" ? "npm ci" : "#{manager} install"
    commands = ["安装依赖：`#{install}`"]
    %w[lint typecheck test build].each do |name|
      command = manager == "npm" ? "npm run #{name}" : "#{manager} #{name}"
      commands << "运行 #{name}：`#{command}`" if scripts.key?(name)
    end
    commands
  rescue JSON::ParserError
    ["先修复 `package.json` 格式，再使用 #{package_manager_for(directory)} 执行项目脚本。"]
  end

  def module_rules(directory)
    manifests = local_manifests(directory)
    rules = []
    if manifests.include?("package.json")
      rules << "JSX/TSX 对外文案必须走 i18n；依赖和脚本使用 #{package_manager_for(directory)}，与现有锁文件保持一致。"
    end
    rules << "Go 代码执行 `gofmt`，核心逻辑使用表驱动测试。" if manifests.include?("go.mod")
    rules << "Python 公共 API 写类型注解，使用 pytest 和 ruff。" if manifests.include?("pyproject.toml")
    rules << "工作流使用最小权限，并固定第三方 Action 的主版本。" if relative_path(directory) == ".github"
    rules << "测试必须隔离数据与外部状态，一个测试用例只验证一件事。" if relative_path(directory) == "tests"
    rules.empty? ? ["遵守父级规则，只在本文件记录本模块确有差异的约束。"] : rules
  end

  def rules_fragment
    profile = TEMPLATE_PROFILES.fetch(@template_name)
    output, status = Open3.capture2e(RbConfig.ruby, RULE_GENERATOR, "--profile", profile, "--compact", "--fragment", "--dry-run")
    raise "规则基线生成失败：#{output}" unless status.success?

    output.strip
  end

  def detect_template
    has_go = manifest_present?("go.mod")
    has_web = manifest_present?("package.json")
    return "go-react-embed" if has_go && has_web
    return "go-api" if has_go
    return "react-web" if has_web

    "generic"
  end

  def manifest_present?(name)
    paths = [File.join(@target, name)] + Dir.glob(File.join(@target, "**", name))
    paths.any? { |path| File.file?(path) && (File.dirname(path) == @target || pertinent_directory?(File.dirname(path))) }
  end

  def package_manager_for(directory)
    current = directory
    loop do
      return "yarn" if File.exist?(File.join(current, "yarn.lock"))
      return "pnpm" if File.exist?(File.join(current, "pnpm-lock.yaml"))
      return "npm" if File.exist?(File.join(current, "package-lock.json"))
      break if current == @target

      parent = File.dirname(current)
      break unless parent.start_with?(@target)

      current = parent
    end
    "yarn"
  end

  def local_manifests(directory)
    MANIFESTS.select { |name| File.exist?(File.join(directory, name)) }
  end

  def manifests_markdown(directory)
    value = local_manifests(directory).map { |name| "`#{name}`" }.join("、")
    value.empty? ? "无独立构建清单" : value
  end

  def render_template(path, context)
    ERB.new(File.read(path, encoding: "UTF-8"), trim_mode: "-").result_with_hash(context)
  end

  def markdown_list(items)
    items.map { |item| "- #{item}" }.join("\n")
  end

  def relative_path(path)
    Pathname.new(path).relative_path_from(Pathname.new(@target)).to_s
  end

  def path_depth(path)
    relative_path(path).split(File::SEPARATOR).reject { |part| part == "." }.length
  end

  def action(path, status, detail)
    { path: relative_path(path), status: status, detail: detail }
  end
end

def parse_options(argv)
  options = { target: Dir.pwd, template_name: "auto", max_depth: 3, dry_run: false, json_output: nil, markdown_output: nil }
  OptionParser.new do |opts|
    opts.banner = "用法：ruby scripts/generate_project_agents.rb [options]"
    opts.on("--target PATH", "目标项目目录，默认当前目录") { |value| options[:target] = value }
    opts.on("--template NAME", "模板：auto, #{TEMPLATE_PROFILES.keys.join(', ')}") { |value| options[:template_name] = value }
    opts.on("--max-depth N", Integer, "扫描模块最大深度，默认 3") { |value| options[:max_depth] = value }
    opts.on("--dry-run", "只展示计划，不写入 AGENTS.md") { options[:dry_run] = true }
    opts.on("--json-output PATH", "可选 JSON 报告路径") { |value| options[:json_output] = value }
    opts.on("--markdown-output PATH", "可选 Markdown 报告路径") { |value| options[:markdown_output] = value }
  end.parse!(argv)
  abort("未知模板：#{options[:template_name]}") unless options[:template_name] == "auto" || TEMPLATE_PROFILES.key?(options[:template_name])
  abort("--max-depth 不能小于 0") if options[:max_depth].negative?
  options
end

def markdown_report(result)
  lines = ["# Project AGENTS Generation Report", "", "> Template: #{result.fetch(:template)}", "", "| 路径 | 状态 | 说明 |", "|------|------|------|"]
  result.fetch(:actions).each { |action| lines << "| #{action.fetch(:path)} | #{action.fetch(:status)} | #{action.fetch(:detail)} |" }
  "#{lines.join("\n")}\n"
end

def write_optional_report(path, content)
  return unless path

  absolute = File.expand_path(path)
  FileUtils.mkdir_p(File.dirname(absolute))
  File.write(absolute, content, encoding: "UTF-8")
end

options = parse_options(ARGV)
result = ProjectAgentGenerator.new(
  target: options.fetch(:target),
  template_name: options.fetch(:template_name),
  max_depth: options.fetch(:max_depth),
  dry_run: options.fetch(:dry_run)
).run
write_optional_report(options[:json_output], "#{JSON.pretty_generate(result)}\n")
write_optional_report(options[:markdown_output], markdown_report(result))
puts JSON.generate(result)
