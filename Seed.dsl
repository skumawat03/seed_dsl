

def env_list="${env}"
println ("Receive Job val=" +env_list)
def cc_id="${id}"
println ("Rec param val=" +cc_id)
def set_val="${SET_FORCE_OK}"
println ("Rec set force val=" +set_val)
Date date = new Date()
String datePart = date.format("yyyyMMdd")
println  ("date is =" +datePart)
def env_name = env_list.split(',')
for(i=0;i<env_name.length;i++){
def get_rel=""
def file = new File('/nas/apps/env/manifests/envManifest_'+env_name[i]+'.txt')
def data= file.eachLine { line ->
    if(line.contains('ENV.BASE.RELEASE')){
         def arr  =  line.split('=')
         get_rel = arr[1]
    }
}
def orderID=""
def file1 = new File('/apps/ansible/orderid.txt')
def o_id = file1.eachLine { line ->
orderID = line
}
println ("Order ID is=" +orderID)

println ("Release is=" +get_rel)
def param1=""

readFileFromWorkspace("/nas/home/oracle/autobuild/EHF_OC/"+env_name[i]+"/auto_deploy/"+orderID+"_"+datePart+"/"+env_name[i]+"_EHF_OC_"+orderID+".properties").eachLine {
  def project_line = it.trim();
  if (project_line.length() == 0 || project_line.substring(0, 1) == '#') {
    print("invalid!!")
    return;
  }
  def arr = project_line.split('=');
  if (arr.length < 8) {
    println("Invalid project line! " + project_line);
    return;
  }
  println ("arr[0]=" + arr[0])
  def job_name   = arr[0]
  println ("arr[1]=" + arr[1])
  def remote_host_key = arr[1]
  println ("arr[2]=" + arr[2])
  def playbook_name = arr[2]

  println ("arr[5]=" + arr[5])
  param1  = arr[5]

  println ("arr[3]=" + arr[3])
  def upstream_job = arr[3]
  String[] str = upstream_job.split(' ')
  def upstr = []
  str.each{
  upstr.push(env_name[i]+'_'+"${it}"+'-'+orderID)
 }
def get_values = upstr.join(",")
upstream_job = get_values
println(upstream_job)

  println ("arr[4]=" + arr[4])
  def email_list  = arr[4]
  def project_name = job_name

  println ("arr[6]=" + arr[6])
  def param2  = arr[6]

  println ("arr[7]=" + arr[7])
  def param3  = arr[7]

  println ("arr[8]=" + arr[8])
  def param4  = arr[8]


    job(env_name[i]+'_'+job_name+'-'+orderID) {
   parameters {
        booleanParam('SET_FORCE_OK')
              }
      logRotator {
        daysToKeep(15)
      }
      publishers {
         mailer(email_list,true,true)
      }
      label ('master')
triggers {
fanInReverseBuildTrigger {
upstreamProjects(upstream_job)
watchUpstreamRecursively(true)
threshold('SUCCESS')
}
      }

wrappers {
buildUserVars()
buildNameSetter {
template(''+orderID+'#${BUILD_USER_ID}#${BUILD_NUMBER}')
runAtStart(true)
runAtEnd(true)
descriptionTemplate(null)
}
}

steps {
        shell('cd /apps/ansible; ./hold_flag_check.sh '+env_name[i]+"_"+job_name+"-"+orderID+" "+env_name[i])
        shell('echo "Going to execute Ansible playbook"')
        ansiblePlaybook("/apps/ansible/" +get_rel+"/" +playbook_name) {
        inventoryPath("/apps/ansible/" +get_rel+"/hosts_" +env_name[i])
        ansibleName("/apps/ansible/" +get_rel+"/" +playbook_name)
        unbufferedOutput( unbufferedOutput = true)
        colorizedOutput( colorizedOutput = false)
        hostKeyChecking( hostKeyChecking = false)
        additionalParameters('-v')
        extraVars {
            extraVar("key", "$remote_host_key", false)
            extraVar("env", ""+env_name[i], false)
            extraVar("date", "$datePart", false)
            extraVar("param1", "$orderID", false)
            extraVar("param2", "$param2", false)
            extraVar("param3", "$param3", false)
            extraVar("param4", "$param4", false)
            extraVar("jobname", "$job_name", false)
            extraVar("set_ok_val", "\${SET_FORCE_OK}", false)
                  }
        }
      }
  }
}
println ("Start of View" +orderID)
println ("ENV NAME" +env_name[i])
def view_name="OC-EHF STREAM-"+env_name[i]
deliveryPipelineView(view_name) {
    allowPipelineStart(true)
    allowRebuild(true)
    showPromotions(true)
    showStaticAnalysisResults(true)
    showTestResults(true)
    pipelineInstances(1)
    showAggregatedPipeline(false)
    columns(1)
    updateInterval(2)
    enableManualTriggers(true)
    showAvatars(true)
    showChangeLog(true)
    showTotalBuildTime(true)
        pipelines {
        component('OC-EHF Deployment Stream', env_name[i]+'_AUTODEPLOY_BEGIN-'+orderID)
    }
    }
println ("END of View" +orderID)
}
