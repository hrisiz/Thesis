class DomainsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_domain, only: [:show, :edit, :update, :destroy, :start, :stop]




  HOST_IP = '192.168.0.102'
  ROOT_PASSWORD = 'hrisiz'
  DB_PASSWORD = 'Martin4o'
  FLLCASTS_FOLDER = "Desktop/heroku/fllcasts"

  # GET /domains
  # GET /domains.json
  def index
    user_id = current_user.id;
    @domains = Domain.where(user_id:user_id);
  end

  # GET /domains/1
  # GET /domains/1.json
  def show
  end

  # GET /domains/new
  def new
    @domain = Domain.new
  end

  # GET /domains/1/edit
  def edit
  end

  # POST /domains
  # POST /domains.json
  def create
   # respond_to do |format|
   #    format.html { redirect_to '/domains', notice: config_fllcast(params[:config]) }
   #  end
  
    user_id = current_user.id;

    @domain = Domain.new(:user_id=>user_id,:domain_name=>params[:domain_name],:domain=>params[:domain])

    respond_to do |format|
      if Domain.where(domain_name:params[:domain_name]).count == 0
        if config_fllcast(params[:config]) && create_the_web(@domain) && @domain.save
          format.html { redirect_to '/domains', notice: 'Domain was successfully created.' }
          format.json { render :show, status: :created, location: @domain }
        else
          format.html { render :new }
          format.json { render json: @domain.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to '/domains/new', notice: 'Domain name already exist !' }
        format.json { render json: @domain.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /domains/1
  # PATCH/PUT /domains/1.json
  def update
    respond_to do |format|
      if @domain.update(domain_params)
        format.html { redirect_to @domain, notice: 'Domain was successfully updated.' }
        format.json { render :show, status: :ok, location: @domain }
      else
        format.html { render :edit }
        format.json { render json: @domain.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /domains/1
  # DELETE /domains/1.json
  def destroy
    kill_docker(@domain)
    @domain.destroy
    respond_to do |format|
      format.html { redirect_to domains_url, notice: 'Domain was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def start
    start_docker(@domain)
    respond_to do |format|
      format.html { redirect_to domains_url, notice: 'Domain was successfully started.' }
      format.json { head :no_content }
    end
  end

  def stop
    stop_docker(@domain);
    respond_to do |format|
      format.html { redirect_to domains_url, notice: 'Domain was successfully stopped.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_domain
      if (@domain = Domain.where(id:params[:id],user_id:current_user.id)).count <= 0
        respond_to do |format|
          format.html { redirect_to domains_url, notice: 'Wrong domain.' }
          format.json { head :no_content }
        end
        else 
          @domain = Domain.find(params[:id])
      end
    end

    def free_port(start_port)
      while `echo 'hrisiz' | sudo -S lsof -i :#{start_port}` != ''  || (Domain.where(port:start_port).count != 0)
        start_port = start_port +1
      end
      return start_port;
    end

    def create_the_web(domain)
      `cd ~/#{FLLCASTS_FOLDER} && docker build -t #{domain.domain_name} .`
      create_new_docker(domain)
      return 1
    end

    def create_new_docker(domain)
      domain.db_port = free_port(3306)
      domain.docker_db_id = `docker run -d -p #{domain.db_port}:3306 --dns=#{HOST_IP} -e MYSQL_ROOT_PASSWORD=#{DB_PASSWORD} mysql`
      sleep(20);
      domain.port = free_port(3000)
      rake_docker = `docker run -d -p #{domain.port}:3000  --restart="always" -e "RAILS_ENV=development" -e "DATABASE_URL=mysql2://root:#{DB_PASSWORD}@#{HOST_IP}:#{domain.db_port}/railscasts_development" #{domain.domain_name} rake db:create db:schema:load `
      sleep(20);
      `docker stop #{rake_docker[0..11]}`
      `docker rm #{rake_docker[0..11]}`
      domain.docker_id = `docker run -d -p #{domain.port}:3000  --restart="always" -e "RAILS_ENV=development" -e "DATABASE_URL=mysql2://root:#{DB_PASSWORD}@#{HOST_IP}:#{domain.db_port}/railscasts_development" #{domain.domain_name}`
      domain.save
    end
    def config_fllcast(config_info)
      config_info.each do |option,value|
        config_change(option,value);
      end
    end
    def kill_docker(domain)
      `docker stop #{domain.docker_id[0..11]}`
      `docker stop #{domain.docker_db_id[0..11]}`
      `docker rm #{domain.docker_id[0..11]}`
      `docker rm #{domain.docker_db_id[0..11]}`
    end

    def start_docker(domain)
      `docker start #{domain.docker_db_id[0..11]}`
      sleep(20)
      `docker start #{domain.docker_id[0..11]}`
    end

    def stop_docker(domain)
      `docker stop #{domain.docker_id[0..11]}`
      `docker stop #{domain.docker_db_id[0..11]}`
    end

    def config_change(option,value)
      string = ""
      File.open("/home/xbeast/#{FLLCASTS_FOLDER}/config/cast_config.yml",'r') do |file|
        file.each do |line|
          if( line =~  /^#{option}: / )
            string += "#{option}: #{value} \n"
          else
            string += line
          end
        end
        File.open("/home/xbeast/#{FLLCASTS_FOLDER}/config/cast_config.yml", "w") {|file1| file1.write(string) }
        file.close
      end
    end
end
