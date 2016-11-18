def check_file_param(params, name, max_size = nil)
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
end