module Authenticatable
  extend ActiveSupport::Concern

  private

  # before_action для эндпоинтов, требующих авторизации по токену студента.
  # Заполняет @current_student.
  def authenticate_student!
    user_id = params[:user_id]

    return render_bad_id unless valid_id?(user_id)

    @current_student = Student.find_by(id: user_id)
    return render_bad_id if @current_student.nil?

    token = bearer_token
    return render_unauthorized if token.blank?

    stored = @current_student.auth_token.to_s
    return render_unauthorized if stored.empty?
    render_unauthorized unless ActiveSupport::SecurityUtils.secure_compare(token, stored)
  end

  def bearer_token
    header = request.authorization.to_s
    match = header.match(/\ABearer\s+(.+)\z/i)
    match && match[1].strip
  end

  def valid_id?(value)
    value.to_s.match?(/\A\d+\z/)
  end
end
