# frozen_string_literal: true

require "fileutils"

module TailwindSetup
  module_function

  def aa_v4?
    Gem::Version.new(ActiveAdmin::VERSION) >= Gem::Version.new("4.0.0.beta1")
  end

  def compile!
    dummy_root = File.expand_path("../dummy", __dir__)
    out_path = File.join(dummy_root, "app/assets/stylesheets/active_admin.css")

    unless aa_v4?
      File.delete(out_path) if File.exist?(out_path)
      return
    end

    aa_path = Gem.loaded_specs["activeadmin"].full_gem_path
    input_path = File.join(dummy_root, "tmp/aa_tailwind_input.css")

    FileUtils.mkdir_p(File.dirname(input_path))
    File.write(input_path, <<~CSS)
      @import "tailwindcss";
      @plugin "#{aa_path}/plugin.js";
      @source "#{aa_path}/app/views/**/*";
      @source "#{aa_path}/lib/active_admin/**/*";
      @source "#{aa_path}/vendor/javascript/flowbite.js";
      @source "#{aa_path}/plugin.js";
      @source "#{dummy_root}/app/admin/**/*";
      @source "#{dummy_root}/app/views/**/*";
    CSS

    cli = Gem.bin_path("tailwindcss-ruby", "tailwindcss")
    cmd = [cli, "-i", input_path, "-o", out_path, "--minify"]
    system(*cmd, out: File::NULL) or raise "tailwindcss compile failed"

    # Append gem's own calendar stylesheet so propshaft serves a single file.
    gem_css = File.expand_path("../../app/assets/stylesheets/activeadmin_calendar.css", __dir__)
    File.open(out_path, "a") { |f| f.puts; f.puts File.read(gem_css) } if File.exist?(gem_css)

    puts "🎨 compiled Tailwind + appended calendar CSS → #{out_path}"
  end
end

RSpec.configure do |config|
  config.before(:suite) { TailwindSetup.compile! }
end
