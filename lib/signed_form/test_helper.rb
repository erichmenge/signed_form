module SignedForm
  module TestHelper
    def permit_all_parameters
      @controller.instance_eval do
        def params
          @permit_all_parameters ||= super.permit!
        end
      end

      if block_given?
        yield
        @controller.remove_instance_variable :@permit_all_parameters
        @controller.singleton_class.send :remove_method, :params
      end
    end
  end
end
