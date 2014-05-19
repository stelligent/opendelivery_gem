static Closure pipelineConfig(String task, String stage) {
    return { project ->
        def pipelineConfig = project / 'properties' / 'se.diabol.jenkins.pipeline.PipelineProperty' 
        pipelineConfig << { stageName stage }
        pipelineConfig << { taskName task }      
    }
}

// pipelines is a map of maps of arrays
// pipelines is a map of pipeline names mapped to maps of stage names mapped to jobs

def create_view(pipeline, triggerjob) {
  view {
    name = pipeline
    configure { view ->
      view.name = 'se.diabol.jenkins.pipeline.DeliveryPipelineView'
      (view / 'name').setValue("${pipeline} View")
      (view / 'noOfPipelines').setValue(3)
      (view / 'noOfColumns').setValue(1)
      (view / 'sorting').setValue("none")
      (view / 'showAvatars').setValue("false")
      (view / 'updateInterval').setValue(2)
      (view / 'showChanges').setValue("false")
      (view / 'showAggregatedPipeline').setValue("false")
      (view / 'componentSpecs' / 'se.diabol.jenkins.pipeline.DeliveryPipelineView_-ComponentSpec' / 'name').setValue(pipeline)
      (view / 'componentSpecs' / 'se.diabol.jenkins.pipeline.DeliveryPipelineView_-ComponentSpec' / 'firstJob').setValue("opendelivery_gem-${triggerjob}-dsl")
    }
  }
}

def pipelines =  [
  "Open Delivery Gem Continuous Delivery Pipeline":[
    "commit":["trigger", "commit"], 
    "acceptance": ["acceptance"]
    ],
  "Open Delivery Gem Production Delivery Pipeline":[
    "production" : ["deploy-to-ruby-gems"]
    ]
  ]

pipelines.each { pipeline, stages ->
  stageList = stages.keySet().toArray()
  create_view(pipeline, stages[stageList[0]].first())

  // the data structure we define the pipelines in is useful for humans to read, but a pain to look-forward through. Translate to something easier to code around.
    def joblist = []
    stages.each { stage, jobs ->
      jobs.each { job ->
        joblist.add([job, stage])
      }
    }
    
    [*joblist, null].collate(2, 1, false).each { currentJob, nextJob ->
    jobName = currentJob[0]
    nextJobName = nextJob == null ? null : nextJob[0]
    stage = currentJob[1]

    job {  
      println "configuring ${jobName}'s pipeline config: ${jobName} / ${stage}"
      configure pipelineConfig(jobName, stage)
      name "opendelivery_gem-${jobName}-dsl"
      multiscm {
        git("https://github.com/stelligent/opendelivery_gem.git", "master") { node ->
          node / skipTag << "true"
        }
      }
      if (jobName.equals("trigger")) {
        triggers {
          scm("* * * * *")
        }
      }
      steps {
        shell("pipeline/${jobName}.sh")
        if (nextJobName != null) {
          downstreamParameterized {
            trigger ("opendelivery_gem-${nextJobName}-dsl", "ALWAYS"){
              currentBuild()
              propertiesFile("environment.txt")
            }
          }
        }
      }
      wrappers {
        rvm("2.0.0")
      }
      publishers {
        extendedEmail("jonny@stelligent.com", "\$PROJECT_NAME - Build # \$BUILD_NUMBER - \$BUILD_STATUS!", """\$PROJECT_NAME - Build # \$BUILD_NUMBER - \$BUILD_STATUS:

        Check console output at \$BUILD_URL to view the results.""") {
          trigger("Failure")
          trigger("Fixed")
        }
      }
    }
  }
}

