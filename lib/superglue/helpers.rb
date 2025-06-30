module Superglue
  module Helpers
    class DigPathTooDeepError < StandardError
      def initialize(depth, max_depth)
        super("Parameter dig path too deep: #{depth} levels (maximum allowed: #{max_depth})")
      end
    end

    MAX_DIG_DEPTH = 50

    def redirect_back_with_props_at(opts)
      if request.referrer && params[:props_at]
        referrer_url = URI.parse(request.referrer)
        referrer_url.query = Rack::Utils
          .parse_nested_query(referrer_url.query)
          .merge({props_at: params[:props_at]})
          .to_query

        redirect_to referrer_url.to_s, opts
      else
        redirect_back(opts)
      end
    end

    def param_to_dig_path(param)
      if param
        path_array = param
          .gsub(/[^\da-zA-Z_=.]+/, "")
          .squeeze(".")
          .split(".")

        if path_array.length > MAX_DIG_DEPTH
          raise DigPathTooDeepError.new(path_array.length, MAX_DIG_DEPTH)
        end

        path_array
      end
    end
  end
end
