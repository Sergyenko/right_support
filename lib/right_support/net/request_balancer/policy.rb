class RightSupport::Net::RequestBalancer::Policy
  def next_endpoint
    raise NotImplementedError, "Subclass responsibility"
  end

  def report_success(endpoint)
    #no-op
  end

  def report_failure(endpoint)
    #no-op
  end
end

