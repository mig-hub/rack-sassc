require 'sassc'

module Rack
  class SassC

    attr_reader :opts

    def initialize app, opts={}
      @app = app

      @opts = {
        check: ENV['RACK_ENV'] != 'production',
        public_location: 'public',
        syntax: :scss,
        css_dirname: :css,
        scss_dirname: :scss,
        create_map_file: true,
      }.merge(opts)

      @opts[:public_location] = ::File.expand_path @opts[:public_location]
    end

    def call env
      handle_path(env['PATH_INFO']) if must_check?(env)
      @app.call env
    end

    def location dirname
      ::File.join @opts[:public_location], dirname.to_s
    end

    def filepath dirname, filename, ext
      ::File.join location(dirname), "#{filename}.#{ext}"
    end

    private

    def must_check? env
      if @opts[:check].respond_to? :call
        @opts[:check].call env
      else
        @opts[:check]
      end
    end

    def handle_path path_info
      return unless path_info[/\/#{@opts[:css_dirname]}\/[^\/]+\.css$/]

      filename = ::File.basename path_info, '.*'
      scss_filepath = filepath(@opts[:scss_dirname], filename, @opts[:syntax])
      return unless ::File.exist?(scss_filepath)

      scss = ::File.read(scss_filepath)
      engine = ::SassC::Engine.new(scss, build_engine_opts(filename))
      css_filepath = filepath(@opts[:css_dirname], filename, :css)

      ::File.open(css_filepath, 'w') do |css_file|
        css_file.write(engine.render)
      end

      if @opts[:create_map_file]
        ::File.open("#{css_filepath}.map", 'w') do |map_file|
          map_file.write(engine.source_map)
        end
      end
    end

    def build_engine_opts filename
      engine_opts = {
        style: :compressed, 
        syntax: @opts[:syntax],
        load_paths: [location(@opts[:scss_dirname])],
      }

      if @opts[:create_map_file]
        engine_opts.merge!({
          source_map_file: "#{filename}.css.map",
          source_map_contents: true,
        })
      end

      if @opts.has_key?(:engine_opts)
        engine_opts.merge! @opts[:engine_opts]
      end

      engine_opts
    end

  end
end

require 'rack/sassc/version'

