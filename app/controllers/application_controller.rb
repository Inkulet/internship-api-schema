class ApplicationController < ActionController::API
  # Ответы под openapi: 400 «некорректный id», 401 «некорректная авторизация»,
  # 405 «Invalid input» на POST /students.
  rescue_from ActiveRecord::RecordNotFound,                    with: :render_bad_id
  rescue_from ActiveRecord::RecordInvalid,                     with: :render_invalid_input
  rescue_from ActionController::ParameterMissing,              with: :render_invalid_input
  rescue_from ActionDispatch::Http::Parameters::ParseError,    with: :render_invalid_input

  private

  def render_bad_id(_exception = nil)
    render json: { error: "Некорректный id студента" }, status: :bad_request
  end

  def render_unauthorized(_exception = nil)
    render json: { error: "Некорректная авторизация" }, status: :unauthorized
  end

  # Семантически 405 — это «Method Not Allowed», но openapi предписывает
  # именно его для «Invalid input» на POST /students. Следуем за спецификацией.
  def render_invalid_input(exception = nil)
    body = { error: "Invalid input" }
    body[:details] = Array(exception_details(exception)) if exception
    render json: body, status: 405
  end

  def exception_details(exception)
    case exception
    when ActiveRecord::RecordInvalid then exception.record.errors.full_messages
    else                                  exception.message
    end
  end
end
