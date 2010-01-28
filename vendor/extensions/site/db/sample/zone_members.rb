canada_zone = ZoneMember.find_by_zoneable_id(35)
canada_zone.zone_id = 3
canada_zone.save!

%W(1 2 3).each { |i| ZoneMember.create(:zone_id => 4, :zoneable => Zone.find(i)) }