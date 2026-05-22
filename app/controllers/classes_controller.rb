class ClassesController < ApplicationController
  # GET /schools/:school_id/classes
  def index
    classes = SchoolClass
                .where(school_id: params[:school_id])
                .order(:number, :letter)

    render json: { data: classes.map(&:to_api_hash) }
  end
end
