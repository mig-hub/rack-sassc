ENV['RACK_ENV'] = 'test'

require 'rack/sassc'
require 'rack/test'
require 'minitest/autorun'

# Simulate a setup where `public` is in the current directory
Dir.chdir('test')

class TestRackSassC < MiniTest::Test

  include Rack::Test::Methods

  KEEP_IN_CSS_DIR = ['already.css']

  def setup
    teardown
    @inner_app = inner_app
    @app_options = {}
  end

  def teardown
    Dir.children('public/css').each do |f|
      ::File.delete("public/css/#{f}") unless KEEP_IN_CSS_DIR.include?(f)
    end
    if ::File.directory?( 'other-public/stylesheets' )
      Dir.children('other-public/stylesheets').each do |f|
        ::File.delete("other-public/stylesheets/#{f}") unless KEEP_IN_CSS_DIR.include?(f)
      end
    end
    if ::File.exist? "public/scss/tmp.scss"
      ::File.delete "public/scss/tmp.scss"
    end
    if ::File.exist? "other-public/sassc/tmp.scss"
      ::File.delete "other-public/sassc/tmp.scss"
    end
  end

  def app
    Rack::Lint.new(Rack::SassC.new(@inner_app, @app_options))
  end

  def inner_app
    Rack::Static.new(lambda {|env|
      [200, {'Content-Type'=>'text/plain'}, ["Inner"]]
    }, {
      urls: ["/css", "/scss"], 
      root: "public"
    })
  end

  def inner_app_other
    Rack::Static.new(lambda {|env|
      [200, {'Content-Type'=>'text/plain'}, ["Inner"]]
    }, {
      urls: ["/stylesheets", "/sassc"], 
      root: "other-public"
    })
  end

  def test_non_css_request_is_served
    get "/"
    assert_equal 200, last_response.status
    assert_equal "Inner", last_response.body
    assert_css_dir_untouched
  end

  def test_existing_file_without_sassc_template_is_served
    # Files that are already css from a library or something.
    get "/css/already.css"
    assert_equal 200, last_response.status
    assert_equal 'text/css', last_response.headers['Content-Type']
    assert last_response.body[/\.already\{color:yellow\}/]
    assert_css_dir_untouched
  end

  def test_non_existing_file_without_sassc_template_is_not_found
    # There is neither a file in css or in scss
    get "/css/notfound.css"
    assert_equal 404, last_response.status
    assert_css_dir_untouched
  end

  def test_file_with_sassc_template_but_wrong_css_path_pass_through
    # There is corresponding file in scss but the css path is wrong
    get "/wrong-css/main.css"
    assert_equal 200, last_response.status
    assert_equal "Inner", last_response.body
    assert_css_dir_untouched
  end

  def test_file_with_sassc_template_is_created_and_served
    get "/css/main.css"
    assert_equal 200, last_response.status
    assert_equal 'text/css', last_response.headers['Content-Type']
    assert last_response.body[/body\{color:yellow\}/]
    assert last_response.body[/sourceMappingURL=main\.css\.map/]
    assert_created_in_css_dir "main.css", "main.css.map"
  end

  def test_file_with_sassc_template_is_uptodate
    ::File.open('public/scss/tmp.scss', 'w') do |file|
      file.write "body{color:yellow}"
    end
    get "/css/tmp.css"
    ::File.open('public/scss/tmp.scss', 'w') do |file|
      file.write "body{color:orange}"
    end
    get "/css/tmp.css"
    assert_equal 200, last_response.status
    assert_equal 'text/css', last_response.headers['Content-Type']
    assert last_response.body[/body\{color:orange\}/]
    refute last_response.body[/yellow/]
    assert last_response.body[/sourceMappingURL=tmp\.css\.map/]
    assert_created_in_css_dir "tmp.css", "tmp.css.map"
  end

  def test_option_to_not_create_map_file
    @app_options = {create_map_file: false}
    get "/css/main.css"
    assert_equal 200, last_response.status
    assert_equal 'text/css', last_response.headers['Content-Type']
    assert last_response.body[/body\{color:yellow\}/]
    refute last_response.body[/sourceMappingURL/]
    assert_created_in_css_dir "main.css"
  end

  def test_middleware_can_be_disabled_via_check_option
    @app_options = {check: false}
    get "/css/main.css"
    assert_equal 404, last_response.status
    assert_css_dir_untouched
  end

  def test_check_option_can_be_a_proc
    @app_options = {
      check: proc{ |env|
        assert_equal '/css/main.css', env['PATH_INFO']
        false
      }
    }
    get "/css/main.css"
    assert_equal 404, last_response.status
    assert_css_dir_untouched
  end

  def test_css_location_option_is_expanded
    local_opts = {css_location: 'other-public/stylesheets'}
    local_app = Rack::SassC.new(inner_app, local_opts)
    assert_equal ::File.expand_path('other-public/stylesheets'), local_app.opts[:css_location]
    # Make sure the original opts hash is unchanged
    assert_equal 'other-public/stylesheets', local_opts[:css_location]
  end

  def test_scss_location_option_is_expanded
    local_opts = {scss_location: 'other-public/sassc'}
    local_app = Rack::SassC.new(inner_app, local_opts)
    assert_equal ::File.expand_path('other-public/sassc'), local_app.opts[:scss_location]
    # Make sure the original opts hash is unchanged
    assert_equal 'other-public/sassc', local_opts[:scss_location]
  end

  def test_filepath
    local_opts = {
      css_location: 'other-public/stylesheets', 
      scss_location: 'other-public/sassc',
      syntax: :sass
    }
    local_app = Rack::SassC.new(inner_app, local_opts)
    assert_equal ::File.join(::File.expand_path('other-public/stylesheets'), 'main.css'), local_app.filepath(:main, :css)
    assert_equal ::File.join(::File.expand_path('other-public/sassc'), 'main.sass'), local_app.filepath(:main, :scss)
  end

  def test_works_with_different_locations_and_syntax
    @inner_app = inner_app_other
    @app_options = {
      css_location: 'other-public/stylesheets',
      scss_location: 'other-public/sassc',
      syntax: :sass
    }
    get "/stylesheets/main.css"
    assert_equal 200, last_response.status
    assert_equal 'text/css', last_response.headers['Content-Type']
    assert last_response.body[/body\{color:blue\}/]
    assert last_response.body[/sourceMappingURL=main\.css\.map/]
    assert_created_in_css_dir "main.css", "main.css.map"
  end

  def test_works_with_absolute_paths
    # @inner_app = inner_app_other
    @app_options = {
      scss_location: ::File.expand_path('other-public/sassc'),
      syntax: :sass
    }
    get "/css/main.css"
    assert_equal 200, last_response.status
    assert_equal 'text/css', last_response.headers['Content-Type']
    assert last_response.body[/body\{color:blue\}/]
    assert last_response.body[/sourceMappingURL=main\.css\.map/]
    assert_created_in_css_dir "main.css", "main.css.map"
  end

  private

  # This will assert the files were created
  # but also fail if other files where created that
  # are not passed as argument. Therefore the list 
  # of files created needs to be exhaustive.
  def assert_created_in_css_dir *created_files
    if @app_options.has_key?(:css_location)
      possible_files = KEEP_IN_CSS_DIR + created_files.dup
      path = @app_options[:css_location]
    else
      possible_files = KEEP_IN_CSS_DIR + created_files
      path = 'public/css'
    end
    assert_equal possible_files.sort, Dir.children(path).sort
  end

  # Sugar for legibility
  def assert_css_dir_untouched
    assert_created_in_css_dir
  end

end

