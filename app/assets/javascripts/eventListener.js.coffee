window.triggerEvent= (e)->
  switch e.type
    when 'updateProperty'
      @bigBro.cvState.uploadTagProperties(e.message.properties,e.message.index)
      
    when 'highlighted'
      @bigBro.propToolbox.activatePropertyControls(e.message.highlight, 
        e.message.box, e.message.properties, e.message.index)
      
    when 'newTag'
      @bigBro.historyManager.addNewTag(e.message)

    when 'moveTagToNewFrame'
      tagToMove = @bigBro.cvState.deleteTag(e.message.frame, e.message.sub)
      @bigBro.cvState.addTagElem(tagToMove, e.message.newFrame)
      
    when 'tagMoving'
      if @bigBro.propToolbox.isPoppupOpen() 
        @bigBro.propToolbox.boxMove(e.message.position)
  
    when 'tagMovingDone'
      @bigBro.historyManager.moveThumbnailTag(e.message.frame, e.message.sub, e.message.type,e.message.data)
      @eventManager.logEvent('tag', 'moved')

    when 'tagFill'
      @bigBro.historyManager.fillThumbnailTag(e.message.frame, e.message.sub, e.message.filled)
      @eventManager.logEvent('tag', 'filled')

    when 'imageMovingDone'
      @eventManager.logEvent('image', 'panned')
      
    when 'last_undo_mouseover'
      @bigBro.cvState.showNextUndo()
      
    when 'last_undo_click'
      deletedTag = @bigBro.cvState.deleteTag()
      unless deletedTag is null
        #pass in deleted tag elem
        @bigBro.historyManager.deleteTag deletedTag
    
    when 'last_undo_mouseout'
      @bigBro.cvState.hideNextUndo()
    
    when 'rotated'
      @bigBro.cvState.updateViewStatus e.message
      @bigBro.cvState.setView e.message

      #rotate the view in historymanager
      @bigBro.historyManager.setView e.message

    when 'severity_value_change'
      @bigBro.cvState.updateSeverityValue e.message

    when 'frameChanged'
      @bigBro.cvState.changeFrame +e.message
      @bigBro.toolbox.updateRotationViews @bigBro.cvState.getView()

$(window).on('mousedown', (e)->
  possibleParents = ['#toolbox_property', '.ui-multiselect-menu', 'g.frameGroup']
  if @bigBro.propToolbox.isPoppupOpen()
    for parent in possibleParents
      return if $(parent).has(e.target).length!=0 
    @bigBro.cvState.deHighlightFrame()
    )
    