module SignedForm
  module TestHelper
    def permit_all_parameters
      mod = Module.new do
        def params
          super.dup.permit!
        end
      end

      @controller.singleton_class.send :include, mod

      if block_given?
        yield
        mod.send :remove_method, :params
      end
    end
  end
end
