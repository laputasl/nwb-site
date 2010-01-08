class ExactTargetList < ActiveRecord::Base
  has_and_belongs_to_many :users
  validates_presence_of :title
  validates_uniqueness_of :list_id, :message => I18n.t("exact_target.validate_unique")
  validates_numericality_of :list_id

  def validate
    if self.new_record?
      errors.add_to_base I18n.translate("exact_target.only_list_can_subscribe_all") if self.subscribe_all_new_users && ExactTargetList.exists?(["subscribe_all_new_users = ?" , true])
    else
      errors.add_to_base I18n.translate("exact_target.only_list_can_subscribe_all") if self.subscribe_all_new_users && ExactTargetList.exists?(["subscribe_all_new_users = ? AND id <> ?" , true, self.id])
    end
  end
end
