window.attachEventListeners= ()->
  $(window).on('updateProperty', (e)->
    this.bigBro.cvState.uploadTagProperties(e.message)
    )

  $(window).on('highlighted', (e)->
    this.bigBro.propToolbox.activatePropertyControls(e.message.highlight, 
      e.message.box, e.message.data)
    )

  $(window).on('needHighlight', (e)->
    indexes = /([0-9]*)_([0-9]*)/.exec(e.message)
    this.bigBro.cvState.highlightCloud(+indexes[1], +indexes[2])
    )

  $(window).on('newTag', (e)->
    this.bigBro.historyManager.addNewTag(e.message.points)
    )

  $(window).on('click', (e)->
    #this.bigBro.propToolbox.activatePropertyControls(false)
    )

  $(window).on('highlightBoxMove', (e)->
    this.bigBro.propToolbox.boxMove(e.message.box, e.message.data)
    )

  $(window).on('opaqueCurrent', (e)->
    this.bigBro.propToolbox.hideSummaries(e.message)
    )

  

  