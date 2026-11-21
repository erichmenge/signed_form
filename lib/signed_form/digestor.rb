require 'set'

module SignedForm
  class Digestor
    attr_accessor :view_paths

    def initialize(template)
      @view_paths = Set.new
      @views  = Set.new
      self << template
    end

    def <<(template)
      virtual_path = get_virtual_path(template)
      raise Errors::UnableToDigest, "Unable to get virtual path from template" unless virtual_path

      @views << virtual_path
      @view_paths += template.view_paths.map(&:to_s)
      @digest = nil
    rescue NoMethodError
      raise Errors::UnableToDigest, "Unable get view paths from template"
    end

    def marshal_dump
      [@views.to_a, to_s]
    end

    def marshal_load(input)
      @views, @digest = input
      @view_paths = []
      @digest.taint if RUBY_VERSION < '2.7'
    end

    def to_s
      @digest ||= SignedForm.digest_store.fetch(@views.sort.join(':')) { hash_files(glob_files) }
    end
    alias_method :digest, :to_s

    def refresh
      @digest = nil
    end

    private

    def glob_files
      globbed_files = []
      view_paths.each do |path|
        @views.each { |view| globbed_files += Dir["#{path}/#{view}.*"] }
      end
      globbed_files
    end

    def hash_files(files)
      raise Errors::UnableToDigest, "No files to digest" if files.empty?

      md5 = Digest::MD5.new
      files.sort.each do |entry|
        File.open(entry) { |f| md5 << f.read }
      end
      md5.to_s
    end

    def get_virtual_path(template)
      template.respond_to?(:virtual_path) ? template.virtual_path : template.instance_variable_get(:@virtual_path)
    end
  end
end
