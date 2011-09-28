Feature: REST request timeout
  In order to enhance system availability for customers
  RightSupport should provide robust REST query interfaces 
  So apps do not become hung during network failures

  Scenario: well-behaved servers
    Given 3 well-behaved servers
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should complete in less than 1 second

  Scenario: faulty servers
    Given 3 faulty servers
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should raise in less than 3 seconds

  Scenario: hung servers
    Given 3 hung servers
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should raise in less than 6 seconds

  Scenario: mixed servers (faulty, well-behaved)
    Given 4 faulty servers
    And 4 well-behaved servers
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should complete in less than 4 seconds

  Scenario: mixed servers (faulty, hung)
    Given 4 faulty servers
    And 4 hung servers
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should raise in less than 12 seconds

  Scenario: mixed servers (well-behaved, hung)
    And 4 well-behaved servers
    Given 4 hung servers
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should complete in less than 8 seconds

  Scenario: mixed servers (faulty, well-behaved, hung)
    Given 1 faulty server
    And 1 well-behaved server
    And 1 hung server
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should complete in less than 3 seconds

  Scenario: mixed servers (condition commented by Tony https://rightscale.acunote.com/projects/2091/tasks/23987#comments)
    Given 3 faulty servers
    And 1 well-behaved servers
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should complete in less than 3 seconds

  Scenario: well-behaved servers using health check
    Given 3 well-behaved servers
    And HealthCheck balancing policy
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should complete in less than 1 second

  Scenario: faulty servers using health check
    Given 3 faulty servers
    And HealthCheck balancing policy
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should raise in less than 3 seconds

  Scenario: mixed servers (faulty, well-behaved) using health check
    Given 4 faulty servers
    And 4 well-behaved servers
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should complete in less than 4 seconds

  Scenario: mixed servers (faulty, hung) using health check
    Given 4 faulty servers
    And 4 hung servers
    And HealthCheck balancing policy
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should raise in less than 12 seconds

  Scenario: mixed servers (well-behaved, hung) using health check
    And 4 well-behaved servers
    Given 4 hung servers
    And HealthCheck balancing policy
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should complete in less than 8 seconds

  Scenario: mixed servers (faulty, well-behaved, hung) using health check
    Given 1 faulty server
    And 1 well-behaved server
    And 1 hung server
    And HealthCheck balancing policy
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should complete in less than 3 seconds

  Scenario: mixed servers (condition commented by Tony https://rightscale.acunote.com/projects/2091/tasks/23987#comments) using health check
    Given 3 faulty servers
    And 1 well-behaved servers
    And HealthCheck balancing policy
    When a client makes a load-balanced request to '/' with timeout 1 and open_timeout 2
    Then the request should complete in less than 3 seconds