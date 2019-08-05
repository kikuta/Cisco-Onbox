import cli

service_internal = ["service internal"]
no_service_internal = ["no service internal"]
hiddencli_list = []
cli_list = []

x = raw_input('Please input exec command with ? >')
print "\n\n *** Hidden CLI Information - ### ", x  ," ### *** \n\n"

cli.configure(service_internal)
output_hidden = cli.execute(x)

for hidden in output_hidden.split("\n"):
    hiddencli_list.append(hidden.split(' ')[2])

cli.configure(no_service_internal)
output = cli.execute(x)

for cli in output.split("\n"):
    cli_list.append(cli.split(' ')[2])

hidden_option = list(set(hiddencli_list) - set(cli_list))

for ho in sorted(hidden_option):
    print ho

print "\n\n *************** \n\n" 
print "Number of Hidden Command in exec mode is :", len(hidden_option) 
print "\n\n *************** \n\n"
