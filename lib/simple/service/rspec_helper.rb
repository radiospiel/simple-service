module ::Simple::Service::RSpecHelper
  def self.included(base)
    base.let(:current_context) { {} }

    base.around do |example|
      if (ctx = current_context)
        ::Simple::Service.with_context(ctx) do
          example.run
        end
      else
        example.run
      end
    end
  end
end
