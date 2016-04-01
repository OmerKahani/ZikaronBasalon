class Manager < ActiveRecord::Base
  has_many :community_leaderships
  has_many :cities, :through => :community_leaderships
  has_many :hosts, :through => :cities
  has_many :witnesses, :through => :cities
  has_one :user, as: :meta, dependent: :destroy
  accepts_nested_attributes_for :user

 	attr_accessible :temp_email, :user_attributes
 	attr_accessor :city_name

	validates_uniqueness_of :temp_email

  def get_hosts(page, filter, query, sort, has_manager)
   sort = 'created_at' if sort.blank?
   hosts = Host.includes(:city, :user).order(sort + " desc").where(filter)
   hosts = hosts.where(:city_id => cities.pluck(:id)) if !user.admin? && !user.sub_admin?
   hosts = hosts.select{ |h| host_in_query(h, query) } if query.present?
   hosts = hosts.select{ |h| obj_has_manager(h, has_manager) } if has_manager.present?
   hosts = paginate(hosts, page)
   hosts
  end

  def get_witnesses(page, filter, query, sort, has_manager)
   sort = 'created_at' if sort.blank?
   witnesses = Witness.includes(:city, :host).order(sort + " desc").where(filter)
   witnesses = witnesses.where(:city_id => cities.pluck(:id)) if !user.admin? && !user.sub_admin?
   witnesses = witnesses.select{ |w| w.full_name.include?(query) } if query.present?
   witnesses = witnesses.select{ |w| obj_has_manager(w, has_manager) } if has_manager.present?
   witnesses = paginate(witnesses, page)
   witnesses
  end

  def get_cities
    if user.admin?
      @cities = City.order('name desc').all
    else
      @cities = City.where(:id => cities.pluck(:id))
    end

    @cities.map{ |c| { id: c.id, name: c.name }}.sort_alphabetical_by{|c| c[:name] }
  end

  def city_name=(name)
  	city = City.find_or_create_by_name(name) if name.present?
  	self.cities.push(city)
  end

  def paginate(arr_name, page)
    unless arr_name.kind_of?(Array)
      arr_name = arr_name.page(page).per(20)
    else
      arr_name = Kaminari.paginate_array(arr_name).page(page).per(20)
    end
    arr_name
  end

  def host_in_query(h, q)
    (h.user && (h.user.full_name.include?(q) || h.user.email.include?(q))) ||
    (h.org_name && h.org_name.include?(q)) ||
    (h.city && h.city.name.include?(q)) ||
    (h.city && h.city.managers.count > 0 && h.city.managers.first.temp_email.include?(q))
  end

  def obj_has_manager(obj, has_manager)
    return false if obj.city.nil?
    if has_manager === "true"
      return obj.city.managers.count > 0
    else
      return obj.city.managers.count == 0
    end 
  end
end
