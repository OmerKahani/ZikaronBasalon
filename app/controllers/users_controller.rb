class UsersController < ApplicationController
	def new
		@type = params[:type]
	end

	def assignrole
		user = User.find(params[:id])
		oppisite_role = user.meta_type == "Host" ? "Guest" : "Host"
		was_never_oppisite_role = user.previous_meta_id.present?
		if params[:changerole] == true
			if !was_never_oppisite_role
				oppisite_role_instance = oppisite_role.constantize.create! #the guest or host
				if oppisite_role == "Host"
					oppisite_role_instance.active = true
					oppisite_role_instance.save!
				end
				#TODO: add to comments table this change
				user.previous_meta_id = user.meta_id
				user.previous_meta_type = user.meta_type
				user.meta = oppisite_role_instance
			else
				user.meta_type,user.previous_meta_type = user.previous_meta_type,user.meta_type #swap meta_type values using Parallel Assignment
				user.previous_meta_id,user.meta_id = user.meta_id,user.previous_meta_id #swap id values using Parallel Assignment
				if user.meta.type == "Host"
					user.meta.active = true
					user.meta.save!
				end
			end
		end
		user.active_this_year = true
		user.save!
		render json: user, status: 201
	end

	def profile
		if current_user.nil? || current_user.meta.nil?
			redirect_to user_session_path
		else
			redirect_to polymorphic_path(current_user.meta)
		end
	end
end
