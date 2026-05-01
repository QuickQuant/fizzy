module Card::Assignable
  extend ActiveSupport::Concern

  included do
    has_many :assignments, dependent: :delete_all
    has_many :assignees, through: :assignments

    scope :unassigned, -> { where.missing :assignments }
    scope :assigned_to, ->(users) { joins(:assignments).where(assignments: { assignee: users }).distinct }
    scope :assigned_by, ->(users) { joins(:assignments).where(assignments: { assigner: users }).distinct }
  end

  def toggle_assignment(user)
    assigned_to?(user) ? unassign(user) : assign(user)
  end

  def assigned_to?(user)
    assignments.any? { |a| a.assignee_id == user.id }
  end

  def assigned?
    assignments.any?
  end

  def replace_assignees(users)
    transaction do
      removed_ids = assignees.where.not(id: users).pluck(:id)
      assignments.where(assignee: removed_ids).delete_all

      added = []
      users.each do |user|
        next if assigned_to?(user)
        assignment = assignments.create assignee: user, assigner: Current.user
        added << user if assignment.persisted?
      end

      track_event :unassigned, assignee_ids: removed_ids if removed_ids.any?
      track_event :assigned, assignee_ids: added.map(&:id) if added.any?
      added.each { |user| watch_by user }
    end

    assignees.reload
  end

  private
    def assign(user)
      assignment = assignments.create assignee: user, assigner: Current.user

      if assignment.persisted?
        watch_by user
        track_event :assigned, assignee_ids: [ user.id ]
      end
    rescue ActiveRecord::RecordNotUnique
      # Already assigned
    end

    def unassign(user)
      destructions = assignments.destroy_by assignee: user
      track_event :unassigned, assignee_ids: [ user.id ] if destructions.any?
    end
end
