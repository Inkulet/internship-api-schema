module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE     = 100

  private

  # Применяет пагинацию, если в запросе есть ?page= или ?per_page=.
  # Без этих параметров возвращает scope как есть — поведение совместимо
  # с openapi (вся коллекция в `data`).
  def paginate(scope)
    return scope unless params[:page].present? || params[:per_page].present?

    page     = [ params[:page].to_i, 1 ].max
    per_page = (params[:per_page].presence || DEFAULT_PER_PAGE).to_i
    per_page = DEFAULT_PER_PAGE if per_page <= 0
    per_page = [ per_page, MAX_PER_PAGE ].min

    scope.limit(per_page).offset((page - 1) * per_page)
  end
end
