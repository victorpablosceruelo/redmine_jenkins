class UpdateJenkinsJobs02 < ActiveRecord::Migration[5.0]

  # Fields to add:
  # :sources_vulnerabilities, :sources_bugs, :sources_code_smells, :sources_sqale_index,
  # :sources_coverage, :sources_duplicated_lines_density, :sources_violations,
  # :sources_alert_status, :sources_lines, :sources_tests, :sources_skipped_tests,
  # :sources_complexity

  # Technical Debt (sqale_index)
  # Effort to fix all Code Smells. The measure is stored in minutes in the database. 
  # An 8-hour day is assumed when values are shown in days.

  # Quality Gate Status (alert_status)
  # State of the Quality Gate associated to your Project. Possible values are : ERROR, OK 
  # WARN value has been removed since 7.6.

  # Unit tests (tests)
  # Number of unit tests.

  # Complexity (complexity)
  # It is the Cyclomatic Complexity calculated based on the number of paths through the code. Whenever the control flow of a function splits, the complexity counter gets incremented by one. Each function has a minimum complexity of 1. This calculation varies slightly by language because keywords and functionalities do.
  def up
    # Quality Gate
    add_column :jenkins_jobs, :sources_alert_status, :string, null: true, default: nil, limit: 10

    # Size
    add_column :jenkins_jobs, :sources_lines, :bigint, default: 0

    # Reliability
    add_column :jenkins_jobs, :sources_reliability_rating, :float, default: 0.0
    add_column :jenkins_jobs, :sources_bugs, :bigint, default: 0

    # Security
    add_column :jenkins_jobs, :sources_security_rating, :float, default: 0.0
    add_column :jenkins_jobs, :sources_vulnerabilities, :bigint, default: 0

    # Maintainability
    add_column :jenkins_jobs, :sources_sqale_rating, :float, default: 0.0
    add_column :jenkins_jobs, :sources_sqale_debt_ratio, :float, default: 0.0
    add_column :jenkins_jobs, :sources_sqale_index, :bigint, default: 0
    add_column :jenkins_jobs, :sources_code_smells, :bigint, default: 0

    # Issues
    add_column :jenkins_jobs, :sources_violations, :bigint, default: 0

    # Coverage
    add_column :jenkins_jobs, :sources_coverage, :float, default: 0.0
    add_column :jenkins_jobs, :sources_tests, :integer, default: 0
    add_column :jenkins_jobs, :sources_skipped_tests, :integer, default: 0

    # Complexity
    add_column :jenkins_jobs, :sources_complexity, :integer, default: 0
    add_column :jenkins_jobs, :sources_duplicated_lines_density, :float, default: 0.0

    add_column :jenkins_jobs, :sources_report_last_update, :datetime, default: "now()"
    # DateTime.now
  end

  def down2
  end
  
  def down
    remove_column :jenkins_jobs, :sources_alert_status
    remove_column :jenkins_jobs, :sources_lines

    remove_column :jenkins_jobs, :sources_reliability_rating
    remove_column :jenkins_jobs, :sources_bugs

    remove_column :jenkins_jobs, :sources_security_rating
    remove_column :jenkins_jobs, :sources_vulnerabilities

    remove_column :jenkins_jobs, :sources_sqale_rating
    remove_column :jenkins_jobs, :sources_sqale_debt_ratio
    remove_column :jenkins_jobs, :sources_sqale_index
    remove_column :jenkins_jobs, :sources_code_smells

    remove_column :jenkins_jobs, :sources_violations

    remove_column :jenkins_jobs, :sources_coverage
    remove_column :jenkins_jobs, :sources_tests
    remove_column :jenkins_jobs, :sources_skipped_tests

    remove_column :jenkins_jobs, :sources_complexity
    remove_column :jenkins_jobs, :sources_duplicated_lines_density
    remove_column :jenkins_jobs, :sources_report_last_update
  end
end
