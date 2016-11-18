def check_file_param(params, name, max_size = nil)
    begin
        # Abort on missing input file
        unless params.include? name and params[name].include? :tempfile
            halt 400
        end

        # Get the file object
        file = params[name][:tempfile]

        # Check the size
        if max_size
            if file.size > max_size
                halt 413
            end
        end
        
        return file
    rescue
        puts params.inspect
        halt 400, "#{name} parameter is malformed"
    end
end