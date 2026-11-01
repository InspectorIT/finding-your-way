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

  test "client can resubmit rejected application and admin sees it" do
    client = User.create!(
      email: "resubmit-client@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Повторный заявитель",
      phone: "+79990000011",
      role: :client
    )

    profile = PsychologistProfile.create!(
      user: client,
      specialization: "Клиническая психология",
      experience_years: 5,
      price_per_session: 3000,
      session_duration: 50,
      bio: "Работа с тревожностью",
      status: :rejected
    )

    sign_in(client)

    get new_psychologist_application_url

    assert_response :success

    assert_select(
      "form[action='#{psychologist_applications_path}'][method='post']"
    )
    assert_select "input[name='_method']", false

    assert_no_difference("PsychologistProfile.count") do
      post psychologist_applications_url, params: {
        psychologist_profile: {
          specialization: "Семейная психология",
          experience_years: 7,
          price_per_session: 3500,
          session_duration: 60,
          bio: "Работа с семейными отношениями"
        }
      }
    end

    assert_redirected_to root_url

    assert_equal "Заявка отправлена на рассмотрение.",
                 flash[:notice]

    assert_predicate profile.reload, :pending?
    assert_equal "Семейная психология", profile.specialization

    admin = User.create!(
      email: "resubmit-admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Администратор",
      phone: "+79990000012",
      role: :admin
    )

    sign_in(admin)

    get admin_psychologist_applications_url

    assert_response :success
    assert_select "h2", text: client.name
  end

  private

  def sign_in(user)
    post auth_login_url, params: {
      email: user.email,
      password: "password123"
    }

    assert_redirected_to root_url
  end
end
