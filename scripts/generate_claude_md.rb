#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "fileutils"
require "optparse"

RuleDoc = Struct.new(:key, :file, :title, :summary, :tags, keyword_init: true)

ROOT = File.expand_path("..", __dir__)
DEFAULT_OUTPUT = "CLAUDE.md"

def output_document_name(path)
  File.basename(path.to_s.empty? ? DEFAULT_OUTPUT : path)
end

DOCS = [
  RuleDoc.new(
    key: "programming",
    file: "programming.md",
    title: "编程通用规范",
    summary: "代码风格、错误处理、测试、版本控制、安全和日志",
    tags: %w[common backend frontend app required]
  ),
  RuleDoc.new(
    key: "design",
    file: "design.md",
    title: "多端产品设计规范",
    summary: "新项目启动门禁、UI 规范方向、docs 文档沉淀和多端规范",
    tags: %w[design h5 desktop-web mac-app android-app frontend app]
  ),
  RuleDoc.new(
    key: "frontend",
    file: "frontend.md",
    title: "前端规范",
    summary: "TypeScript、React、状态管理、CSS、性能、安全和测试",
    tags: %w[frontend h5 desktop-web react web]
  ),
  RuleDoc.new(
    key: "go",
    file: "go.md",
    title: "Go 规范",
    summary: "Go 项目结构、错误处理、并发、DI、测试、性能和 Go + React embed",
    tags: %w[go backend api service]
  ),
  RuleDoc.new(
    key: "python",
    file: "python.md",
    title: "Python 规范",
    summary: "Python 环境、类型、异步、数据库、测试和常用库",
    tags: %w[python backend api service]
  ),
  RuleDoc.new(
    key: "database-migrations",
    file: "database-migrations.md",
    title: "数据库迁移规范",
    summary: "迁移版本、建表、索引、启动迁移、回滚和 CI/CD",
    tags: %w[database migration backend api service]
  ),
  RuleDoc.new(
    key: "database-queries",
    file: "database-queries.md",
    title: "数据库查询规范",
    summary: "SQL 编写、索引、查询优化、EXPLAIN 和 ORM",
    tags: %w[database sql backend api service]
  ),
  RuleDoc.new(
    key: "database-sync",
    file: "database-sync.md",
    title: "数据库同步规范",
    summary: "全量、增量、实时同步、一致性、冲突解决和监控",
    tags: %w[database sync backend service]
  ),
  RuleDoc.new(
    key: "deployment",
    file: "deployment.md",
    title: "服务部署规范",
    summary: "发布检查、迁移、产物备份、健康检查、回滚和 CI/CD",
    tags: %w[deployment backend api service ops]
  ),
  RuleDoc.new(
    key: "linux-server",
    file: "linux-server.md",
    title: "Linux 服务器规范",
    summary: "安全基线、监控、备份、日志、性能调优、Docker 和应急响应",
    tags: %w[linux ops deployment service]
  ),
  RuleDoc.new(
    key: "version-control",
    file: "version-control.md",
    title: "版本管理规范",
    summary: "分支策略、语义化版本、Build 号、CHANGELOG、.gitignore 和 Git 工作流",
    tags: %w[version git common required]
  )
].freeze

PROFILES = {
  "h5" => {
    name: "H5 移动网页",
    docs: %w[programming design frontend version-control]
  },
  "desktop-web" => {
    name: "电脑版网页 / 后台 / SaaS",
    docs: %w[programming design frontend database-queries version-control]
  },
  "mac-app" => {
    name: "macOS App",
    docs: %w[programming design version-control]
  },
  "android-app" => {
    name: "Android App",
    docs: %w[programming design version-control]
  },
  "go-api" => {
    name: "Go 后端服务",
    docs: %w[programming go database-migrations database-queries deployment linux-server version-control]
  },
  "go-react-embed" => {
    name: "Go + React embed 全栈",
    docs: %w[programming design frontend go database-migrations database-queries deployment linux-server version-control]
  },
  "python-api" => {
    name: "Python 后端服务",
    docs: %w[programming python database-migrations database-queries deployment linux-server version-control]
  },
  "data-sync" => {
    name: "数据库同步 / ETL",
    docs: %w[programming database-sync database-queries database-migrations deployment version-control]
  },
  "full" => {
    name: "完整规则集",
    docs: DOCS.map(&:key)
  }
}.freeze

class RuleSelector
  def initialize(options)
    @options = options
  end

  def selected_docs
    if @options[:all]
      return DOCS
    end

    profile_keys = Array(@options[:profiles])
    explicit_keys = Array(@options[:docs])
    selected_keys = profile_keys.flat_map { |profile| profile_docs(profile) } + explicit_keys

    return docs_by_keys(selected_keys) unless selected_keys.empty?
    return interactive_selection if $stdin.tty? && $stdout.tty?

    docs_by_keys(PROFILES.fetch("go-react-embed")[:docs])
  end

  private

  def profile_docs(profile)
    unless PROFILES.key?(profile)
      abort("未知画像：#{profile}。可选：#{PROFILES.keys.join(", ")}")
    end

    PROFILES.fetch(profile)[:docs]
  end

  def docs_by_keys(keys)
    normalized = keys.map(&:to_s).flat_map { |item| item.split(",") }.map(&:strip).reject(&:empty?)
    docs = normalized.uniq.map do |key|
      DOCS.find { |doc| doc.key == key || doc.file == key } ||
        abort("未知文档：#{key}。可选：#{DOCS.map(&:key).join(", ")}")
    end
    ensure_required_docs(docs)
  end

  def ensure_required_docs(docs)
    required = DOCS.select { |doc| doc.tags.include?("required") }
    missing_required = required.reject { |required_doc| docs.any? { |doc| doc.key == required_doc.key } }
    docs + missing_required
  end

  def interactive_selection
    prompt = try_tty_prompt
    if prompt
      selected_keys = prompt.multi_select(
        "选择要整合进 #{document_name} 的规则文档：",
        DOCS.map { |doc| { name: "#{doc.title} - #{doc.summary}", value: doc.key } },
        default: %w[programming design frontend version-control],
        per_page: 12
      )
      return docs_by_keys(selected_keys)
    end

    fallback_selection
  end

  def try_tty_prompt
    require "tty-prompt"
    TTY::Prompt.new(symbols: { marker: ">", radio_on: "x", radio_off: " " })
  rescue LoadError
    nil
  end

  def fallback_selection
    puts "未检测到 tty-prompt，将使用基础终端选择。安装提示：gem install tty-prompt"
    puts "目标输出：#{document_name}"
    puts
    DOCS.each_with_index do |doc, index|
      puts "#{index + 1}. #{doc.title}（#{doc.file}）- #{doc.summary}"
    end
    puts
    print "请输入编号，多个用逗号分隔；直接回车使用 Go + React embed 推荐组合："
    answer = $stdin.gets&.strip

    if answer.nil? || answer.empty?
      return docs_by_keys(PROFILES.fetch("go-react-embed")[:docs])
    end

    indexes = answer.split(",").map(&:strip).reject(&:empty?).map do |part|
      Integer(part, exception: false) || abort("编号不是数字：#{part}")
    end
    keys = indexes.map do |index|
      DOCS.fetch(index - 1) { abort("编号超出范围：#{index}") }.key
    end
    docs_by_keys(keys)
  end

  def document_name
    output_document_name(@options[:output])
  end
end

class RulesBundleBuilder
  def initialize(docs, options)
    @docs = docs
    @options = options
  end

  def build
    [
      front_matter,
      instructions,
      source_index,
      body
    ].join("\n\n")
  end

  private

  def document_name
    output_document_name(@options[:output])
  end

  def front_matter
    profile_names = Array(@options[:profiles]).map { |key| PROFILES.fetch(key, { name: key })[:name] }
    profile_line = profile_names.empty? ? "自定义选择" : profile_names.join("、")

    <<~MARKDOWN.strip
      # #{document_name}

      > 由 `scripts/generate_claude_md.rb` 于 #{Date.today.iso8601} 生成。
      > 规则画像：#{profile_line}
      > 生成来源：Alma 规则库。
    MARKDOWN
  end

  def instructions
    <<~MARKDOWN.strip
      ## 使用说明

      - 本文件是面向 Claude / Codex / 其他 AI 编程助手的整合规则入口。
      - 若本文件与项目内更具体、更晚出现的 `AGENTS.md`、`CLAUDE.md` 或用户指令冲突，以更具体、更晚出现的指令为准。
      - AI 开工前先判断当前仓库是新项目、半成品还是既有项目迭代；判断不清时按新项目处理。
      - 新项目或规则缺失时，先生成/更新 `AGENTS.md`、`CLAUDE.md`、`PRODUCT_OVERVIEW.md` 或等价文档，写清产品定义、技术栈、设计规范、UI token、多语言计划、版本和验收标准。
      - 新项目关键决策应沉淀到 `docs/product-brief.md`、`docs/architecture.md`、`docs/design-system.md`、`docs/ui-tokens.md`、`docs/i18n.md` 和 `docs/decisions/`，不要只依赖 memory 或聊天记录。
      - 新项目第一轮沟通只问 6-8 个高价值主题：定位、用户场景、首版范围、平台设备、设计方向、多语言、数据库/数据权限、交付验收；能从仓库判断的内容写成默认假设。
      - 架构、数据库、部署、测试、权限等工程决策先给最佳实践建议，再让用户确认；不要把选型责任全丢给用户。
      - UI 规范按平台和应用类型先给 2-4 套推荐方向，再让用户选择；选定后沉淀到 `docs/design-system.md`、`docs/ui-tokens.md` 等仓库文档。
      - 架构、设计规范、数据库、多语言、部署和验收等关键决策必须落入仓库文档；memory 和聊天记录不能作为唯一事实来源。
      - 涉及界面项目时，先按设计规范与用户确认平台、用户、核心场景、视觉气质、信息密度、UI 体系和计划支持语言，再进入实现。
      - 修改代码后必须同步版本号、CHANGELOG 和必要的产品概览文档。
      - 不得输出或提交密钥、Token、凭据、个人隐私数据。
    MARKDOWN
  end

  def source_index
    lines = @docs.map { |doc| "- `#{doc.file}`：#{doc.summary}" }
    (["## 本次整合文档"] + lines).join("\n")
  end

  def body
    @docs.map do |doc|
      content = File.read(File.join(ROOT, doc.file)).strip
      <<~MARKDOWN.strip
        ---

        # #{doc.title}

        > 来源：`#{doc.file}`

        #{content}
      MARKDOWN
    end.join("\n\n")
  end
end

def parse_options(argv)
  options = {
    profiles: [],
    docs: [],
    output: DEFAULT_OUTPUT,
    all: false,
    dry_run: false,
    force: false,
    list: false
  }

  parser = OptionParser.new do |opts|
    opts.banner = "用法：ruby scripts/generate_claude_md.rb [options]"

    opts.on("-p", "--profile NAME", "按项目画像选择文档，可重复。可选：#{PROFILES.keys.join(", ")}") do |value|
      options[:profiles] << value
    end

    opts.on("-d", "--docs LIST", "指定文档 key，逗号分隔。可选：#{DOCS.map(&:key).join(", ")}") do |value|
      options[:docs].concat(value.split(",").map(&:strip))
    end

    opts.on("-o", "--output PATH", "输出文件，默认 #{DEFAULT_OUTPUT}") do |value|
      options[:output] = value
    end

    opts.on("--all", "整合全部文档") do
      options[:all] = true
    end

    opts.on("--dry-run", "只输出到终端，不写文件") do
      options[:dry_run] = true
    end

    opts.on("-f", "--force", "允许覆盖已有输出文件") do
      options[:force] = true
    end

    opts.on("--list", "列出可用项目画像和文档") do
      options[:list] = true
    end

    opts.on("-h", "--help", "显示帮助") do
      puts opts
      exit 0
    end
  end

  parser.parse!(argv)
  options
rescue OptionParser::ParseError => e
  warn e.message
  warn parser
  exit 1
end

def print_catalog
  puts "项目画像："
  PROFILES.each do |key, profile|
    puts "- #{key}: #{profile[:name]}（#{profile[:docs].join(", ")}）"
  end
  puts
  puts "规则文档："
  DOCS.each do |doc|
    puts "- #{doc.key}: #{doc.file} - #{doc.summary}"
  end
end

def output_path(path)
  File.expand_path(path, ROOT)
end

def write_output(path, content, force)
  if File.exist?(path) && !force
    abort("输出文件已存在：#{path}。如需覆盖，请加 --force。")
  end

  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, "#{content}\n")
end

options = parse_options(ARGV)

if options[:list]
  print_catalog
  exit 0
end

docs = RuleSelector.new(options).selected_docs
content = RulesBundleBuilder.new(docs, options).build

if options[:dry_run]
  puts content
else
  target = output_path(options[:output])
  write_output(target, content, options[:force])
  puts "已生成：#{target}"
  puts "整合文档：#{docs.map(&:file).join(", ")}"
end
