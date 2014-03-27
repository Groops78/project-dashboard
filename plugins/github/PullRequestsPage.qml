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
import "../../components"
import "../../ubuntu-ui-extras"
import "../../ubuntu-ui-extras/listutils.js" as List
import ".."

PluginPage {
    id: page
    title: i18n.tr("Pull Requests")

    property var plugin

    property var allIssues: List.filter(plugin.issues, function(issue) {
        return issue.isPullRequest
    }).sort(function(a, b) { return b.number - a.number })

    actions: [
        Action {
            id: newIssueAction
            iconSource: getIcon("add")
            text: i18n.tr("New Pull")
            onTriggered: PopupUtils.open(Qt.resolvedUrl("NewPullRequestsPage.qml"), plugin, {repo: repo, action: reload})
        },

        Action {
            id: filterAction
            text: i18n.tr("Filter")
            iconSource: getIcon("filter")
            onTriggered: filterPopover.show()
            visible: !wideAspect
        }
    ]

    flickable: sidebar.expanded ? null : listView

    onFlickableChanged: {
        if (flickable === null) {
            listView.topMargin = 0
            listView.contentY = 0
        } else {
            listView.topMargin = units.gu(9.5)
            listView.contentY = -units.gu(9.5)
        }
    }

    ListView {
        id: listView
        anchors {
            right: parent.right
            left: sidebar.right
            top: parent.top
            bottom: parent.bottom
        }
        model: allIssues
        delegate: PullRequestListItem {
            issue: modelData
            show: selectedFilter(issue)
        }
        clip: true
    }

    Label {
        anchors.centerIn: listView
        text: settings.get("showClosedTickets", false) ? i18n.tr("No pull requests") : i18n.tr("No open pull requests")
        visible: List.filteredCount(allIssues, selectedFilter) === 0
        fontSize: "large"
        opacity: 0.5
    }

    property var selectedFilter: allFilter

    function filter(issue) {
        return (issue.open || settings.get("showClosedTickets", false))
    }

    property var allFilter: function(issue) {
        return filter(issue) ? true : false
    }

    property var createdFilter: function(issue) {
        return issue.user && issue.user.login === github.user.login && filter(issue) ? true : false
    }

    Scrollbar {
        flickableItem: listView
    }

    Sidebar {
        id: sidebar
        width: units.gu(30)
        expanded: wideAspect
        Item {
            id: sidebarContents
            width: parent.width
            height: childrenRect.height
        }
    }

    Component {
        id: viewMenu

        Popover {
            height: childrenRect.height
            Column {
                width: parent.width


//                ListItem.ValueSelector {
//                    text: i18n.tr("Sort By")
//                    values: [i18n.tr("Number"), i18n.tr("Assignee"), i18n.tr("Milestone")]
//                    selectedIndex: {
//                        if (sort === "number") return 0
//                        if (sort === "assignee") return 1
//                        if (sort === "milestone") return 2
//                    }

//                    onSelectedIndexChanged: {
//                        if (selectedIndex === 0) doc.set("sort", "number")
//                        if (selectedIndex === 1) doc.set("sort", "assignee")
//                        if (selectedIndex === 2) doc.set("sort", "milestone")
//                    }
//                }
            }
        }
    }

    DefaultSheet {
        id: filterPopover

        title: i18n.tr("Filter")

        Component.onCompleted: {
            filterPopover.__leftButton.text = i18n.tr("Close")
            filterPopover.__leftButton.color = filterPopover.__rightButton.__styleInstance.defaultColor
            filterPopover.__foreground.style = Theme.createStyleComponent(Qt.resolvedUrl("../../ubuntu-ui-extras/SuruSheetStyle.qml"), filterPopover)
        }

        contentsHeight: mainView.height
        Item {
            anchors.fill: parent
            anchors.margins: -units.gu(1)

            Column {
                id: filterColumn
                width: parent.width

                ListItem.Standard {
                    text: i18n.tr("Show closed issues")
                    onClicked: closedCheckbox.triggered(closedCheckbox)
                    CheckBox {
                        id: closedCheckbox
                        anchors {
                            right: parent.right
                            rightMargin: units.gu(1.5)
                            verticalCenter: parent.verticalCenter
                        }

                        style: SuruCheckBoxStyle {}
                        checked: settings.get("showClosedTickets", false)
                        onTriggered: checked = settings.sync("showClosedTickets", checked)
                    }
                }

                ListItem.Header {
                    text: i18n.tr("Filter")
                }

                ListItem.SingleValue {
                    text: i18n.tr("All Requests")
                    selected: allFilter === selectedFilter
                    onClicked: selectedFilter = allFilter
                    value: List.filteredCount(allIssues, allFilter)
                }

                ListItem.SingleValue {
                    text: i18n.tr("Yours")
                    selected: createdFilter === selectedFilter
                    onClicked: selectedFilter = createdFilter
                    value: List.filteredCount(allIssues, createdFilter)
                }

    //            ListItem.SingleValue {
    //                text: i18n.tr("Mentioning you")
    //                value: "1"
    //            }
            }
        }
    }

    states: [
        State {
            when: sidebar.expanded

            ParentChange {
                target: filterColumn
                parent: sidebarContents
                width: sidebarContents.width
                x: 0
                y: 0
            }

            StateChangeScript {
                script: {
                    filterPopover.hide()
                }
            }
        }
    ]
}
