module MainFrame.View where

import Prelude hiding (div)
import Contact.Lenses (_contacts, _newContact)
import Contact.View (renderContacts, renderContact, renderNewContact)
import Contract.View (renderContractSetup, renderContractDetails)
import Css (applyWhen, buttonClasses, classNames, hideWhen)
import Data.Lens (view)
import Data.Maybe (Maybe(..))
import Effect.Aff.Class (class MonadAff)
import Halogen (ComponentHTML)
import Halogen.HTML (a, button, div, div_, header, main, nav, text)
import Halogen.HTML.Events (onClick)
import MainFrame.Lenses (_contactState, _overlay, _screen, _templates)
import MainFrame.Types (Action(..), Card(..), ChildSlots, Screen(..), State, Overlay(..))
import Material.Icons as Icon
import Template.View (renderTemplateLibrary, renderTemplateDetails)
import Welcome.View (renderHome)

render :: forall m. MonadAff m => State -> ComponentHTML Action ChildSlots m
render state =
  let
    currentOverlay = view _overlay state

    currentScreen = view _screen state
  in
    div
      [ classNames [ "grid", "grid-rows-main", "h-full", "overflow-hidden" ] ]
      [ header
          [ classNames [ "relative" ] ]
          [ navbar currentOverlay
          , menu currentOverlay currentScreen
          ]
      , main
          [ classNames [ "relative", "bg-lightblue", "text-blue" ] ]
          [ screen state
          , card state
          ]
      ]

navbar :: forall m. MonadAff m => Maybe Overlay -> ComponentHTML Action ChildSlots m
navbar currentOverlay =
  nav
    [ classNames [ "sticky", "top-0", "flex" ] ]
    [ button
        [ classNames $ buttonClasses <> [ "text-midblue" ] ]
        [ Icon.image ]
    , nav
        [ classNames [ "flex", "flex-1", "justify-end" ] ]
        [ navButton Icon.wallet Nothing
        , navButton menuIcon $ Just $ ToggleOverlay Menu
        ]
    ]
  where
  menuIcon = if currentOverlay == Just Menu then Icon.close else Icon.menu

  navButton icon action =
    button
      [ classNames $ buttonClasses <> [ "text-green" ]
      , onClick $ const $ action
      ]
      [ icon ]

menu :: forall m. MonadAff m => Maybe Overlay -> Screen -> ComponentHTML Action ChildSlots m
menu currentOverlay currentScreen =
  div
    [ wrapperClassNames ]
    [ nav
        [ classNames [ "bg-gray", "mx-0.5", "flex", "flex-col" ] ]
        [ menuItem "Welcome screen" (Just $ SetScreen Home) (currentScreen == Home)
        , menuItem "Quick access library" (Just $ ToggleCard TemplateLibrary) false
        , menuItem "Contacts" (Just $ SetScreen Contacts) (currentScreen == Contacts)
        , menuItem "Library" Nothing false
        , menuItem "Docs" Nothing false
        , menuItem "Support" Nothing false
        ]
    ]
  where
  wrapperClassNames = classNames $ [ "absolute", "w-full", "z-20" ] <> hideWhen (currentOverlay /= Just Menu)

  menuItem label action active =
    a
      [ classNames $ [ "p-1", "hover:text-green", "hover:cursor-pointer" ] <> applyWhen active "text-green"
      , onClick $ const action
      ]
      [ text label ]

screen :: forall m. MonadAff m => State -> ComponentHTML Action ChildSlots m
screen state =
  let
    currentScreen = view _screen state

    contacts = view (_contactState <<< _contacts) state
  in
    div
      [ classNames [ "h-full" ] ]
      [ case currentScreen of
          Home -> renderHome state
          Contacts -> ContactAction <$> renderContacts contacts
          ViewContract contractInstance -> renderContractDetails contractInstance
          SetupContract contractTemplate -> renderContractSetup contractTemplate
      ]

card :: forall m. MonadAff m => State -> ComponentHTML Action ChildSlots m
card state =
  let
    contacts = view (_contactState <<< _contacts) state

    newContact = view (_contactState <<< _newContact) state

    templates = view _templates state
  in
    div
      [ classNames cardClasses ]
      [ button
          [ classNames $ buttonClasses <> [ "text-green", "absolute", "top-0", "right-0" ]
          , onClick $ const $ Just CloseCard
          ]
          [ Icon.close ]
      , case state.card of
          Just NewContact -> ContactAction <$> renderNewContact contacts newContact
          Just (EditContact contact) -> ContactAction <$> renderContact contact
          Just TemplateLibrary -> renderTemplateLibrary templates
          Just (TemplateDetails contractTemplate) -> renderTemplateDetails contractTemplate
          Just (ContractDetails contractInstance) -> renderContractDetails contractInstance
          Nothing -> div_ []
      ]
  where
  cardClasses =
    [ "absolute"
    , "top-1"
    , "left-1"
    , "right-1"
    , "bottom-0"
    , "z-10"
    , "bg-white"
    , "mt-0"
    , "p-1"
    , "transition-all"
    , "duration-400"
    , "transform"
    , "translate-y-0"
    ]
      <> applyWhen (state.card == Nothing) "translate-y-full"