require 'sassc'

module Rack
  class SassC

    attr_reader :opts

    def initialize app, opts={}
      @app = app

      @opts = {
        check: ENV['RACK_ENV'] != 'production',
        syntax: :scss,
        css_location: 'public/css',
        scss_location: 'public/scss',
        create_map_file: true,
      }.merge(opts)

      @opts[:css_location] = ::File.expand_path @opts[:css_location]
      @opts[:scss_location] = ::File.expand_path @opts[:scss_location]
    end

    def call env
      dup._call env
    end

    def _call env
      handle_path(env['PATH_INFO']) if must_check?(env)
      @app.call env
    end

    def filepath filename, type
      location = @opts[type==:css ? :css_location : :scss_location]
      ext = type==:scss ? @opts[:syntax] : type
      ::File.join location, "#{filename}.#{ext}"
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

      filename = ::File.basename path_info, '.*'
      scss_filepath = filepath(filename, :scss)
      return unless ::File.exist?(scss_filepath)

      css_filepath = filepath(filename, :css)
      return unless css_filepath[/#{path_info}/]

      scss = ::File.read(scss_filepath)
      engine = ::SassC::Engine.new(scss, build_engine_opts(filename))

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
        load_paths: [@opts[:scss_location]],
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

