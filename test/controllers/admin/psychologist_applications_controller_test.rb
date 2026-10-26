require "test_helper"

class Admin::PsychologistApplicationsControllerTest < ActionDispatch::IntegrationTest
  test "admin can approve an application and promote its owner" do
    admin = create_user("admin@example.com", :admin)
    client = create_user("applicant@example.com", :client)
    profile = create_profile(client)

    sign_in(admin)

    patch admin_psychologist_application_url(profile),
          params: { status: "approved" }

    assert_redirected_to admin_psychologist_applications_url
    assert_predicate profile.reload, :approved?
    assert_predicate client.reload, :psychologist?
  end

  test "admin can reject an application without promoting its owner" do
    admin = create_user("admin-reject@example.com", :admin)
    client = create_user("applicant-reject@example.com", :client)
    profile = create_profile(client)

    sign_in(admin)

    patch admin_psychologist_application_url(profile),
          params: { status: "rejected" }

    assert_redirected_to admin_psychologist_applications_url
    assert_predicate profile.reload, :rejected?
    assert_predicate client.reload, :client?
  end

  test "client cannot access the moderation page" do
    client = create_user("ordinary-client@example.com", :client)
    sign_in(client)

    get admin_psychologist_applications_url

    assert_response :forbidden
  end

  test "anonymous visitor cannot access the moderation page" do
    get admin_psychologist_applications_url

    assert_response :unauthorized
  end

  test "admin cannot assign an unsupported application status" do
    admin = create_user("admin-invalid@example.com", :admin)
    client = create_user("applicant-invalid@example.com", :client)
    profile = create_profile(client)

    sign_in(admin)

    patch admin_psychologist_application_url(profile),
          params: { status: "admin" }

    assert_redirected_to admin_psychologist_applications_url
    assert_predicate profile.reload, :pending?
    assert_predicate client.reload, :client?
  end

  private

  def sign_in(user)
    post auth_login_url, params: {
      email: user.email,
      password: "password123"
    }
  end

  def create_user(email, role)
    User.create!(
      email: email,
      password: "password123",
      password_confirmation: "password123",
      name: email.split("@").first,
      phone: "+79990000001",
      role: role
    )
  end

  def create_profile(user)
    PsychologistProfile.create!(
      user: user,
      specialization: "Клиническая психология",
      experience_years: 5,
      price_per_session: 3000,
      session_duration: 50,
      bio: "Работа с тревожностью",
      status: :pending
    )
  end
end
