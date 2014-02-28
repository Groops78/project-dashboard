/*
 * Project Dashboard - Manage everything about your projects in one app
 * Copyright (C) 2014 Michael Spencer
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import "../../backend/services"

Page {
    id: dialog

    title: i18n.tr("New Issue")

    property string repo
    property var action

    TextField {
        id: nameField
        placeholderText: i18n.tr("Title")
        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
            margins: units.gu(2)
        }
    }

    TextArea {
        id: descriptionField
        placeholderText: i18n.tr("Description")

        anchors {
            left: parent.left
            right: parent.right
            top: nameField.bottom
            bottom: parent.bottom
            margins: units.gu(2)
        }
    }

    tools: ToolbarItems {
        locked: true
        opened: true

        back: ToolbarButton {
            text: i18n.tr("Cancel")
            iconSource: getIcon("back")

            onTriggered: {
                pageStack.pop()
            }
        }

        ToolbarButton {
            text: i18n.tr("Create")
            iconSource: getIcon("add")

            onTriggered: {
                busyDialog.show()
                request = github.newIssue(repo, nameField.text, descriptionField.text, function(response) {
                    busyDialog.hide()
                    pageStack.pop()
                    dialog.action()
                })
            }
        }
    }

    property var request

    Dialog {
        id: busyDialog
        title: i18n.tr("Creating Issue")

        ActivityIndicator {
            running: busyDialog.visible
            implicitHeight: units.gu(5)
            implicitWidth: implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Button {
            text: i18n.tr("Cancel")
            onTriggered: {
                request.abort()
                busyDialog.hide()
            }
        }
    }
}
