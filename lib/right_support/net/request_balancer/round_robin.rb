class RightSupport::Net::RequestBalancer::RoundRobin < Policy
  def next_endpoint(endpoints)
    result = @endpoints[ @counter % @endpoints.size ]
    @counter += 1
    return result
  end
end
