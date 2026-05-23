module Authenticatable
  extend ActiveSupport::Concern

  private

  # before_action для эндпоинтов, требующих авторизации по токену студента.
  # Заполняет @current_student.
  #
  # Порядок проверок (важен для контракта openapi):
  #   1) формат id (число) — иначе 400;
  #   2) существование студента — иначе 400;
  #   3) Bearer-токен присутствует — иначе 401;
  #   4) токен совпадает (constant-time) — иначе 401.
  #
  # Это даёт лёгкую утечку существования id (400 vs 401), но openapi
  # для DELETE предписывает именно эти два кода — следуем за спецификацией.
  def authenticate_student!
    user_id = params[:user_id]

    return render_bad_id unless valid_id?(user_id)

    @current_student = Student.find_by(id: user_id)
    return render_bad_id if @current_student.nil?

    token = bearer_token
    return render_unauthorized if token.blank?

    stored = @current_student.auth_token.to_s
    return render_unauthorized if stored.empty?
    # secure_compare сравнивает за постоянное время — защита от
    # тайминг-атаки, которая могла бы подбирать токен побайтово.
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
