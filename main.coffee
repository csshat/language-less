# Deps

{css, utils} = require 'octopus-helpers'
{_} = utils


# Private fns

_declaration = ($$, lessMixinSyntax, interpolatedSyntax, property, value, modifier) ->
  return if not value? or value == ''

  value = modifier(value) if modifier

  value = "~\"#{value}\"" if interpolatedSyntax

  if lessMixinSyntax
    $$ ".#{property}(#{value});"
  else
    $$ "#{property}: #{value};"


renderColor = (color, colorVariable) ->
  if color.a < 1
    "fade(#{colorVariable}, #{100 - color.a * 100})"
  else
    renderVariable(colorVariable)


_comment = ($, showComments, text) ->
  return unless showComments
  $ "// #{text}"


defineVariable = (name, value, options) ->
  "@#{name}: #{value};"


renderVariable = (name) -> "@#{name}"


_convertColor = _.partial(css.convertColor, renderColor)


_startSelector = ($, selector, selectorOptions, text) ->
  return unless selector
  $ '%s%s', utils.prettySelectors(text, selectorOptions), ' {'


_endSelector = ($, selector) ->
  return unless selector
  $ '}'


class Less

  render: ($) ->
    $$ = $.indents
    declaration = _.partial(_declaration, $$, false, false)
    mixin = _.partial(_declaration, $$, true, @options.useInterpolationSyntax)
    comment = _.partial(_comment, $, @options)
    unit = _.partial(css.unit, @options.unit)
    convertColor = _.partial(_convertColor, @options)
    fontStyles = _.partial(css.fontStyles, declaration, convertColor, unit, @options.quoteType)

    selectorOptions =
      separator: @options.selectorTextStyle
      selector: @options.selectorType
      maxWords: 3
      fallbackSelectorPrefix: 'layer'
    startSelector = _.partial(_startSelector, $, @options.selector, selectorOptions)
    endSelector = _.partial(_endSelector, $, @options.selector)

    if @type == 'textLayer'
      for textStyle in css.prepareTextStyles(@options.inheritFontStyles, @baseTextStyle, @textStyles)

        if @options.showComments
          comment(css.textSnippet(@text, textStyle))

        if @options.selector
          if textStyle.ranges
            selectorText = utils.textFromRange(@text, textStyle.ranges[0])
          else
            selectorText = @name

          startSelector(selectorText)

        if not @options.inheritFontStyles or textStyle.base
          if @options.showAbsolutePositions
            declaration('position', 'absolute')
            declaration('left', @bounds.left, unit)
            declaration('top', @bounds.top, unit)

          if @bounds
            if @bounds.width == @bounds.height
              mixin('size', @bounds.width, unit)
            else
              mixin('size', "#{unit(@bounds.width)}, #{unit(@bounds.height)}")

          mixin('opacity', @opacity)

          if @shadows
            declaration('text-shadow', css.convertTextShadows(convertColor, unit, @shadows))

        fontStyles(textStyle)

        endSelector()
        $.newline()
    else
      if @options.showComments
        comment("Style for \"#{utils.trim(@name)}\"")

      startSelector(@name)

      if @options.showAbsolutePositions
        declaration('position', 'absolute')
        declaration('left', @bounds.left, unit)
        declaration('top', @bounds.top, unit)

      if @bounds
        if @bounds.width == @bounds.height
          mixin('size', @bounds.width, unit)
        else
          mixin('size', "#{unit(@bounds.width)}, #{unit(@bounds.height)}")

      mixin('opacity', @opacity)

      if @background
        declaration('background-color', @background.color, convertColor)

        if @background.gradient
          mixin('background-image', css.convertGradients(convertColor, {gradient: @background.gradient, @bounds}))

      if @borders
        border = @borders[0]
        declaration('border', "#{unit(border.width)} #{border.style} #{convertColor(border.color)}")

      mixin('border-radius', @radius, css.radius)

      if @shadows
        mixin('box-shadow', css.convertShadows(convertColor, unit, @shadows))

      endSelector()


module.exports = {defineVariable, renderVariable, renderClass: Less}
