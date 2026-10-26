require "test_helper"

class PsychologistApplicationsControllerTest < ActionDispatch::IntegrationTest
  test "client application stays pending and cannot assign a role" do
    client = User.create!(
      email: "application-client@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Клиент",
      phone: "+79990000001"
    )

    post auth_login_url, params: {
      email: client.email,
      password: "password123"
    }

    assert_redirected_to root_url

    assert_difference("PsychologistProfile.count", 1) do
      post psychologist_applications_url, params: {
        psychologist_profile: {
          specialization: "Клиническая психология",
          experience_years: 5,
          price_per_session: 3000,
          session_duration: 50,
          bio: "Работа с тревожностью",
          status: "approved",
          user_id: 999
        }
      }
    end

    assert_redirected_to root_url

    profile = client.reload.psychologist_profile

    assert_equal client, profile.user
    assert_predicate profile, :pending?
    assert_predicate client, :client?
    refute_includes PsychologistProfile.approved, profile
  end

  test "anonymous visitor cannot submit an application" do
    assert_no_difference("PsychologistProfile.count") do
      post psychologist_applications_url
    end

    assert_response :unauthorized
  end
end
