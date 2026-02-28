class ArticlesRequestPolicy < ApplicationPolicy
  def index?
    reader_or_admin?
  end

  def show?
    reader_or_admin?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user.present?
      return scope.all if user.reader? || user.admin?

      scope.none
    end
  end

  private

  def admin?
    user&.admin?
  end

  def reader_or_admin?
    user&.reader? || user&.admin?
  end
end
