

recognized_boolean_arguments = ['externalize']
recognized_paramatered_arguments = ['job', 'in']

def parseargs(args):
	arg_list = {}
	for arg in recognized_boolean_arguments:
		arg_list[arg] = False
	for arg_id in range(len(args)):
		arg = args[arg_id]
		if arg[0:2] == '--':
			arg_name = arg[2:]
			if arg_name in recognized_boolean_arguments:
				arg_list[arg_name] = True
			elif arg_name in recognized_paramatered_arguments:
				arg_list[arg_name] = args[arg_id+1]
			else:
				print("Unrecognized argument " + arg[2:])
				exit(-1)
		elif arg_id == 1:
			arg_list['job'] = arg
	return arg_list
