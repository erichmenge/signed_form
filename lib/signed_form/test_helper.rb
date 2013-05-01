module SignedForm
  module TestHelper
    def permit_all_parameters
      @controller.singleton_class.class_eval do
        def params
          super.dup.permit!
        end
      end

      if block_given?
        yield
        @controller.singleton_class.send :remove_method, :params
      end
    end
  end
end
