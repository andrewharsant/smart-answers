# encoding: UTF-8
require_relative '../../test_helper'
require_relative 'flow_test_helper'

class MaternityPaternityCalculatorTest < ActiveSupport::TestCase
  include FlowTestHelper

  setup do
    setup_for_testing_flow 'maternity-paternity-calculator'
  end
  ## Q1
  should "ask what type of leave or pay you want to check" do
    assert_current_node :what_type_of_leave?
  end
  
  ##
  ## Maternity flow
  ##
  context "answer maternity" do
    setup do
      add_response :maternity
    end
    ## QM1
    should "ask when the baby due date is" do
      assert_current_node :baby_due_date_maternity?
    end

    context "test lower earning limits returned" do
      should "return lower_earning_limit of £107" do
        dd =Date.parse("1 January 2013")
        add_response dd
        add_response :yes
        add_response 1.month.ago(dd)
        add_response :yes
        add_response :yes
        add_response "200"
        assert_state_variable "lower_earning_limit", sprintf("%.2f",107) 
      end
      should "return lower_earning_limit of £102" do
        dd =Date.parse("1 January 2012")
        add_response dd
        add_response :yes
        add_response 1.month.ago(dd)
        add_response :yes
        add_response :yes
        add_response "200"
        assert_state_variable "lower_earning_limit", sprintf("%.2f",102) 
      end
    end

    context "answer 2 months from now" do
      setup do
        @two_months_from_now = 2.months.since(Date.today).strftime("%Y-%m-%d")
        add_response @two_months_from_now
      end
      ## QM2
      should "ask if the employee has a contract with you" do
        assert_current_node :employment_contract?
      end
      context "answer yes" do
        setup do
          add_response :yes
        end
        ## QM3
        should "ask when the employee wants to start their leave" do
          assert_current_node :date_leave_starts?
        end
        context "answer 2 months from now" do
          setup do
            add_response @two_months_from_now
          end
          ## QM4
          should "ask if the employee worked for you before or on this date" do
            assert_current_node :did_the_employee_work_for_you?
          end
          context "answer yes" do
            setup do
              add_response :yes
            end
            ## QM5
            should "ask if the employee is on your payroll" do
              assert_current_node :is_the_employee_on_your_payroll?
            end
            context "answer yes" do
              setup do
                add_response :yes
              end
              ## QM6
              should "ask what the employees average weekly earnings are" do
                assert_current_node :employees_average_weekly_earnings?
              end
              context "answer 135.40" do
                setup do
                  add_response 135.40
                end
                should "calculate dates and pay amounts" do
                  two_months_time = 2.months.since(Date.today)
                  start_of_week = two_months_time - two_months_time.wday
                  assert_state_variable "leave_start_date", two_months_time
                  assert_state_variable "leave_end_date", 52.weeks.since(two_months_time)
                  assert_state_variable "notice_of_leave_deadline", 15.weeks.ago(start_of_week)
                  assert_state_variable "pay_start_date", two_months_time
                  assert_state_variable "pay_end_date", 39.weeks.since(two_months_time)
                  assert_state_variable "smp_a", (135.40 * 0.9).round(2).to_s
                  assert_state_variable "smp_b", (135.40 * 0.9).round(2).to_s
                end
                should "calculate and present the result" do
                  assert_phrase_list :maternity_leave_info, [:maternity_leave_table]
                  assert_current_node :maternity_leave_and_pay_result
                end
              end #answer 135.40
            end #answer yes to QM5 on payroll
            context "answer no" do
              should "state that you they are not entitled to pay" do
                add_response :no
                assert_state_variable "not_entitled_to_pay_reason", :must_be_on_payroll
                assert_current_node :maternity_leave_and_pay_result
              end
            end
          end #answer yes to QM4
          context "answer no" do
            should "state that you they are not entitled to pay" do
              add_response :no
              assert_state_variable "not_entitled_to_pay_reason", :not_worked_long_enough
              assert_current_node :maternity_leave_and_pay_result
            end
          end
        end
      end # answer Yes to QM2 employee has contract?
      context "no contract" do
        setup do
          add_response :no
        end
        should "ask when the employee wants to start their leave" do
          assert_current_node :date_leave_starts?
        end
        context "answer 2 months from now" do
          setup do
            add_response @two_months_from_now
          end
          ## QM4
          should "ask if the employee worked for you before or on this date" do
            assert_current_node :did_the_employee_work_for_you?
          end
          context "answer yes" do
            setup do
              add_response :yes
            end
            ## QM5
            should "ask if the employee is on your payroll" do
              assert_current_node :is_the_employee_on_your_payroll?
            end
            context "answer yes" do
              setup do
                add_response :yes
              end
              ## QM6
              should "ask what the employees average weekly earnings are" do
                assert_current_node :employees_average_weekly_earnings?
              end
              context "answer 101.00" do
                setup do
                  add_response 101.00
                end
                should "display not eligible for leave nor pay" do
                  assert_phrase_list :maternity_leave_info, [:not_entitled_to_statutory_maternity_leave]
                  assert_state_variable "not_entitled_to_pay_reason", :must_earn_over_threshold
                end
              end
            end
          end
        end 
      end # no to QM2 employee has contract?
    end
  end # Maternity flow
  
  
  ##
  ## Paternity flow
  ##
  context "answer paternity" do
    setup { add_response :paternity }

    ## QP0
    should "ask whether to check for leave or pay for adoption" do
      assert_current_node :leave_or_pay_for_adoption?
    end

    context "answer no" do
      setup { add_response :no }
      ## QP1
      should "ask for the due date" do
        assert_current_node :baby_due_date_paternity?
      end

      context "due date given as 3 months from now" do
        setup do
          @three_months_from_now = 3.months.since(Date.today).strftime("%Y-%m-%d")
          add_response @three_months_from_now
        end

        ## QP2 
        should "ask if and what context the employee is responsible for the childs upbringing" do
          assert_current_node :employee_responsible_for_upbringing?
        end

        context "is biological father or partner and responsible for upbringing" do
          setup { add_response :yes }
          
          ## QP3
          should "ask if employee worked for you before employment_start" do
            assert_current_node :employee_work_before_employment_start? 
          end

          context "answer yes" do
            setup { add_response :yes }

            # QP4
            should "ask if employee has an employee contract" do
              assert_current_node :employee_has_contract_paternity?
            end

            context "answer yes" do
              setup { add_response :yes }

              # QP5
              should "be entitled to leave" do
                assert_phrase_list :paternity_leave_info, [:paternity_entitled_to_leave]
              end

              should "ask if employee will be employed at employment_end" do
                assert_current_node :employee_employed_at_employment_end_paternity?
              end

              context "answer yes" do
                setup { add_response :yes }

                # QP6
                should "ask if employee is on payroll" do
                  assert_current_node :employee_on_payroll_paternity?
                end

                context "answer yes" do
                  setup { add_response :yes }

                  # QP7
                  should "ask for average weekly earnings" do
                    assert_current_node :employee_average_weekly_earnings_paternity?
                  end

                  context "answer 500.55" do
                    setup do 
                      add_response 500.55
                      @three_months_time = 3.months.since(Date.today)
                      @leave_notice = @three_months_time - @three_months_time.wday
                    end

                    should "have p_notice_leave qualify" do
                      assert_state_variable "p_notice_leave", 15.weeks.ago(@leave_notice)
                    end

                    should "calculate dates and pay amounts" do
                      expected_start = @leave_notice
                      @expected_week = expected_start .. expected_start + 6.days
                      @notice_of_leave_deadline = qualifying_start = 15.weeks.ago(expected_start)
                      @qualifying_week = qualifying_start .. qualifying_start + 6.days
                      @relevant_period = "#{8.weeks.ago(qualifying_start).to_s(:long)} and #{qualifying_start.to_s(:long)}"
                      
                      assert_state_variable "relevant_period", @relevant_period
                      assert_state_variable "employment_start", 26.weeks.ago(expected_start)
                      assert_state_variable "employment_end", @three_months_time 
                      assert_state_variable "spp_rate", sprintf("%.2f",135.45) 
                    end

                    should "display employee is entitled to pay" do
                      assert_phrase_list :paternity_pay_info, [:paternity_entitled_to_pay]
                      assert_current_node :paternity_leave_and_pay
                    end
                  end #answer 500.55

                  context "answer 120.25" do
                    setup { add_response 120.25 }

                    should "calculate dates and pay amounts" do
                      assert_state_variable "spp_rate", sprintf("%.2f",108.23) 
                      assert_current_node :paternity_leave_and_pay
                    end 
                  end

                  context "answer 102.25" do
                    setup { add_response 102.25 }

                    should "paternity not entitled to pay because earnings too low" do
                      assert_phrase_list :paternity_pay_info, [:paternity_not_entitled_to_pay_intro, :must_earn_over_threshold, :paternity_not_entitled_to_pay_outro]
                      assert_current_node :paternity_leave_and_pay
                    end 
                  end
                end  # yes - QP6 on payroll  

                #QP6 - not on payroll:
                context "answer no" do
                  setup { add_response :no }

                  should "state that they are not entitled for pay because not on payroll" do
                    assert_phrase_list :paternity_pay_info, [:paternity_not_entitled_to_pay_intro, :must_be_on_payroll, :paternity_not_entitled_to_pay_outro]
                    assert_current_node :paternity_leave_and_pay
                  end
                end
              end
              #QP5 - not employed at end of relevant period
              context "answer no" do
                setup { add_response :no }
                
                should "state that they are not entitled to pay because not employed at end date" do  
                  assert_phrase_list :paternity_pay_info, [:paternity_not_entitled_to_pay_intro, :must_be_employed_by_you, :paternity_not_entitled_to_pay_outro]
                  assert_current_node :paternity_leave_and_pay
                end
              end
            end
            #QP4 - no employment contract
            context "answer no" do
              setup { add_response :no }

              should "not be entitled to leave" do
                assert_phrase_list :paternity_leave_info, [:paternity_not_entitled_to_leave]
              end
              #QP5
              should "ask if employee will be employed at employment_end" do
                assert_current_node :employee_employed_at_employment_end_paternity?
              end

              context "answer yes" do
                setup { add_response :yes }

                # QP6
                should "ask if employee is on payroll" do
                  assert_current_node :employee_on_payroll_paternity?
                end

                context "answer yes" do
                  setup { add_response :yes }

                  # QP7
                  should "ask for average weekly earnings" do
                    assert_current_node :employee_average_weekly_earnings_paternity?
                  end

                  context "answer 107.00" do
                    setup { add_response 107.00 }

                    should "display employee is entitled to pay" do
                      assert_phrase_list :paternity_pay_info, [:paternity_entitled_to_pay]
                      assert_current_node :paternity_leave_and_pay
                    end 
                  end #answer 107
                end
              end
            end # no employment contract
          end # worked for you before employment start
          # Q3 - did not work for you
          context "answer no" do
            setup { add_response :no }

            should "state that they are not entitled to leave or pay because not worked long enough" do  
              assert_phrase_list :not_entitled_reason, [:not_worked_long_enough]
              assert_current_node :paternity_not_entitled_to_leave_or_pay
            end
          end
        end 
        #Q2 - not a father, partner nor husband
        context "answer no" do
          setup { add_response :no }

          should "state that they are not entitled to leave or pay because they're not responsible for upbringing" do
            assert_phrase_list :not_entitled_reason, [:not_responsible_for_upbringing]
            assert_current_node :paternity_not_entitled_to_leave_or_pay
          end
        end
      end #due date 3 months from now
    end #QP0 - no
  

    ##
    ## Paternity Adoption
    ##
    context "answer yes" do
      setup { add_response :yes }
      ## QAP1
      should "ask for date the child was matched with employee" do
        assert_current_node :employee_date_matched_paternity_adoption?
      end

      context "date matched date given as 3 months ago" do
        setup { add_response 3.months.ago(Date.today).strftime("%Y-%m-%d") }

        # QAP2
        should "ask for the date the adoption placement will start" do
          assert_current_node :padoption_date_of_adoption_placement?
        end

        context "placement date given as 2 months ahead" do
          setup { add_response 2.months.since(Date.today).strftime("%Y-%m-%d") }

          # QAP3
          should "ask if employee is responsible for upbringing" do
            assert_current_node :padoption_employee_responsible_for_upbringing?
          end

          context "answer yes" do
            setup { add_response :yes }

            # QAP4
            should "ask if employee started on or before employment_start" do
              assert_current_node :padoption_employee_start_on_or_before_employment_start?
            end

            context "answer yes" do
              setup { add_response :yes }
              
              # QAP5
              should "ask if employee has an employment contract" do
                 assert_current_node :padoption_have_employee_contract?
              end

              context "answer yes" do
                setup { add_response :yes }

                should "be entitled to leave" do
                  assert_phrase_list :padoption_leave_info, [:padoption_entitled_to_leave]
                end
                
                # QAP6
                should "ask if employee will be employed at employment_end" do
                   assert_current_node :padoption_employed_at_employment_end?
                end

                context "answer yes" do
                  setup { add_response :yes }
                  
                  # QAP7
                  should "ask if employee is on payroll" do
                     assert_current_node :padoption_employee_on_payroll?
                  end

                  context "answer yes" do
                    setup { add_response :yes }
                    
                    # QAP8
                    should "ask for employee avg weekly earnings" do
                      assert_current_node :padoption_employee_avg_weekly_earnings?
                    end

                    context "answer 500.55" do
                      setup do 
                        add_response 500.55
                        @three_months_time = 3.months.ago(Date.today)
                        @leave_notice = @three_months_time - @three_months_time.wday
                      end

                      should "calculate dates and pay amounts" do
                        expected_start = @leave_notice
                        @expected_week = expected_start .. expected_start + 6.days
                        @notice_of_leave_deadline = qualifying_start = 15.weeks.ago(expected_start)
                        @qualifying_week = qualifying_start .. qualifying_start + 6.days
                        @relevant_period = "#{8.weeks.ago(qualifying_start).to_s(:long)} and #{qualifying_start.to_s(:long)}"
                        
                        assert_state_variable "ap_qualifying_week", @qualifying_week
                        assert_state_variable "relevant_period", @relevant_period
                        assert_state_variable "employment_start", 26.weeks.ago(expected_start)
                        assert_state_variable "employment_end", @three_months_time 
                        assert_state_variable "sapp_rate", sprintf("%.2f",135.45) 
                      end

                      should "display pay info" do
                        assert_phrase_list :padoption_pay_info, [:padoption_entitled_to_pay]
                        assert_current_node :padoption_leave_and_pay
                      end
                    end

                    context "answer 120.25" do
                      setup { add_response 120.25 }

                      should "calculate dates and pay amounts" do
                        assert_state_variable "sapp_rate", 108.23.to_s 
                      end 
                    end

                    context "answer 90" do
                      setup { add_response 90.25 }

                      should "paternity adoption not entitled to pay because earn too little" do
                        assert_phrase_list :padoption_pay_info, [:padoption_not_entitled_to_pay_intro, :must_earn_over_threshold, :padoption_not_entitled_to_pay_outro]
                        assert_current_node :padoption_leave_and_pay
                      end 
                    end
                  end # is on payroll

                  context "answer no" do
                    # outcome 4AP
                    setup { add_response :no }
                    
                    should "paternity adoption not entitled to pay because not on payroll" do
                      assert_phrase_list :padoption_pay_info, [:padoption_not_entitled_to_pay_intro, :must_be_on_payroll, :padoption_not_entitled_to_pay_outro]
                      assert_current_node :padoption_leave_and_pay
                    end
                  end

                end

                context "answer no" do
                  # outcome 4AP
                  setup { add_response :no }

                  should "paternity adoption not entitled to pay because not employed at end" do
                    assert_phrase_list :padoption_pay_info, [:padoption_not_entitled_to_pay_intro, :pa_must_be_employed_by_you, :padoption_not_entitled_to_pay_outro]
                    assert_current_node :padoption_leave_and_pay
                  end
                end

              end

              context "answer no" do
                # outcome 3AP
                setup { add_response :no }

                should "paternity adoption not entitled to leave because no contract" do
                  assert_phrase_list :padoption_leave_info, [:padoption_not_entitled_to_leave] 
                end
                #TODO: complete this flow with different pay scenarios
              end


            end

            context "answer no" do
              # outcome 5AP
              setup { add_response :no } 

              should "not entitled to paternity adoption leave nor pay because not employed long enough" do
                assert_phrase_list :not_entitled_reason, [:not_worked_long_enough]
                assert_current_node :padoption_not_entitled_to_leave_or_pay
              end
            end
          end

          context "answer no" do
            # outcome 5AP
            setup { add_response :no }
            should "not entitled to leave or pay because not responsible for upbringing" do
              assert_phrase_list :not_entitled_reason, [:not_responsible_for_upbringing]
              assert_current_node :padoption_not_entitled_to_leave_or_pay
            end
          end
        end
      end # Paternity Adoption flow

    end #QP0 - yes
  end # Paternity flow
  
  

  ##
  ## Adoption flow
  ##
  context "answer adoption" do
    setup do
      add_response :adoption
    end
    ## QA0
    should "ask if the check is for maternity or paternity leave" do
      assert_current_node :maternity_or_paternity_leave_for_adoption?
    end
    context "answer maternity" do
      setup do
        add_response :maternity
      end
      ## QA1
      should "ask the date of the adoption match" do
        assert_current_node :date_of_adoption_match?
      end
      context "answer 1 month ago" do
        setup do
          add_response 1.month.ago.strftime("%Y-%m-%d")
        end
        ## QA2
        should "ask the date of the adoption placement" do
          assert_current_node :date_of_adoption_placement?
        end
        context "answer 1 month from now" do
          setup do
            add_response 1.month.since(Date.today).strftime("%Y-%m-%d")
          end
          ## QA3
          should "ask if the employee has a contract" do
            assert_current_node :adoption_employment_contract?
          end
          context "answer yes to contract" do
            setup do
              add_response :yes
            end
            ## QA4
            should "ask when the employee wants to start their leave" do
              assert_state_variable "employee_has_contract_adoption", 'yes'
              assert_current_node :adoption_date_leave_starts?
            end
            context "answer 1 month from now" do
              setup do
                add_response 1.month.since(Date.today).strftime("%Y-%m-%d")
              end
              ## QA5
              should "ask if the employee worked for you before ..." do
                assert_current_node :adoption_did_the_employee_work_for_you?
              end
              context "answer yes" do
                setup do
                  add_response :yes
                end
                ## QA6
                should "ask if the employee is on your payroll" do
                  assert_current_node :adoption_is_the_employee_on_your_payroll?
                end
                context "answer yes" do
                  setup do
                    add_response :yes
                  end
                  ## QA7
                  should "ask what the average weekly earnings of the employee" do
                    assert_current_node :adoption_employees_average_weekly_earnings?
                  end
                  context "answer below the lower earning limit" do
                    should "state they are entitled to leave but not entitled to pay" do
                      add_response 100
                      assert_phrase_list :adoption_leave_info, [:adoption_leave_table]
                      assert_phrase_list :adoption_pay_info, [:adoption_not_entitled_to_pay_intro, :must_earn_over_threshold, :adoption_not_entitled_to_pay_outro]
                      assert_current_node :adoption_leave_and_pay
                    end
                  end
                  context "answer above the earning limit" do
                    should "give adoption leave and pay details" do
                      add_response 200
                      assert_phrase_list :adoption_leave_info, [:adoption_leave_table]
                      assert_phrase_list :adoption_pay_info, [:adoption_pay_table]
                      assert_current_node :adoption_leave_and_pay
                    end
                  end
                end # yes to QA6 - on payroll
                context "answer no" do
                  should " state they are entitled to leave but not entitled to pay" do
                    add_response :no
                    assert_phrase_list :adoption_leave_info, [:adoption_leave_table]
                    assert_phrase_list :adoption_pay_info, [:adoption_not_entitled_to_pay_intro, :must_be_on_payroll, :adoption_not_entitled_to_pay_outro]
                    assert_current_node :adoption_leave_and_pay
                  end
                end
              end # yes to QA5 - worked for you before
              context "answer no" do
                should "state they are not entitled to leave or pay" do
                  add_response :no
                  assert_current_node :adoption_not_entitled_to_leave_or_pay
                end
              end
            end
          end # yes to QA3 - has a contract
          # now run through the branch where there is no contract as that means not entitled to leave
          context "answer no to contract" do
            setup do
              add_response :no
            end
            should "ask when the employee wants to start their leave" do
              assert_state_variable "employee_has_contract_adoption", 'no'
              assert_current_node :adoption_date_leave_starts?
            end
            context "answer 1 month from now" do
              setup do
                add_response 1.month.since(Date.today).strftime("%Y-%m-%d")
              end
              ## QA5
              should "ask if the employee worked for you before ..." do
                assert_current_node :adoption_did_the_employee_work_for_you?
              end
              context "answer yes" do
                setup do
                  add_response :yes
                end
                ## QA6
                should "ask if the employee is on your payroll" do
                  assert_current_node :adoption_is_the_employee_on_your_payroll?
                end
                context "answer yes" do
                  setup do
                    add_response :yes
                  end
                  ## QA7
                  should "ask what the average weekly earnings of the employee" do
                    assert_current_node :adoption_employees_average_weekly_earnings?
                  end
                  context "answer below the lower earning limit" do
                    should "state they are not entitled to leave and not entitled to pay" do
                      add_response 100
                      assert_phrase_list :adoption_leave_info, [:adoption_not_entitled_to_leave]
                      assert_phrase_list :adoption_pay_info, [:adoption_not_entitled_to_pay_intro, :must_earn_over_threshold, :adoption_not_entitled_to_pay_outro]
                      assert_current_node :adoption_leave_and_pay
                    end
                  end
                  context "answer above the earning limit" do
                    should "not entitled to leave but entitled to pay" do
                      add_response 200
                      assert_phrase_list :adoption_leave_info, [:adoption_not_entitled_to_leave]
                      assert_phrase_list :adoption_pay_info, [:adoption_pay_table]
                      assert_current_node :adoption_leave_and_pay
                    end
                  end
                end # yes to QA6 - on payroll
                context "answer no" do
                  should " state they are not entitled to leave nor pay" do
                    add_response :no
                    assert_phrase_list :adoption_leave_info, [:adoption_not_entitled_to_leave]
                    assert_phrase_list :adoption_pay_info, [:adoption_not_entitled_to_pay_intro, :must_be_on_payroll, :adoption_not_entitled_to_pay_outro]
                    assert_current_node :adoption_leave_and_pay
                  end
                end
              end # yes to QA5 - worked for you before
              context "answer no" do
                should "state they are not entitled to leave or pay" do
                  add_response :no
                  assert_current_node :adoption_not_entitled_to_leave_or_pay
                end
              end
            end
          end # no to contract (QA3)
        end
      end
    end
  end # adoption
end
