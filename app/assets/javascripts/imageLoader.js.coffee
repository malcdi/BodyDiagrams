class window.ImageLoader
  
  constructor:()->
    @bodyImages = {}
    @gender = ["female", "male"]
    @views = [0, 1, 2, 3]
    for i of @views
      for j of @gender
        key = @gender[j] + "_" + @views[i]
        @bodyImages[key] = new Image()
        @bodyImages[key].src = "/assets/" + key + ".png"
    @getBodyImage = (gender, index) ->
      @bodyImages[gender + "_" + index]

    @getBodyImageSrc = (gender, index) ->
      @bodyImages[gender + "_" + index].src

    @painPatterns = {}
    @painTypes = ["Sharp", "Dull", "Numb"]
    @painSeverity = [1, 2, 3, 4, 5]
    for i of @painSeverity
      for j of @painTypes
        key = @painTypes[j] + "_" + @painSeverity[i]
        @painPatterns[key] = new Image()
        pngName = ""
        if @painTypes[j] is "Sharp"
          pngName = "cross"
        else if @painTypes[j] is "Numb"
          pngName = "dot"
        else pngName = "cross"  if @painTypes[j] is "Dull"
        @painPatterns[key].src = "/assets/pain_type/" + pngName + "_" + @painSeverity[i] + ".png"
    @getPainPatternImage = (type, severity) ->
      @painPatterns[type + "_" + severity]

    @getPainPatternImageSrc = (type, severity) ->
      @painPatterns[type + "_" + severity].src