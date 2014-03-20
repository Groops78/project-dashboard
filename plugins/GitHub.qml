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
import "../backend"
import "../components"
import "../backend/services"
import "../ubuntu-ui-extras"
import "../ubuntu-ui-extras/listutils.js" as List
import "github"

Plugin {
    id: githubPlugin

    name: "github"
    canReload: false

    property ListModel issues: ListModel {

    }

    items: [
        PluginItem {
            title: "Issues"
            value: List.filteredCount(issues, function (issue) {
                return issue.open
            }) + " (" + issues.count + ")"
            page: IssuesPage {
                plugin: githubPlugin
            }
        },

        PluginItem {
            title: "Pull Requests"
        }
    ]

    onSave: {
        // Save projects
        var list = []
        for (var i = 0; i < issues.count; i++) {
            var issue = issues.get(i).modelData
            list.push(issue.toJSON())
        }

        doc.set("issues", list)
    }

    onLoaded: {
        print("Loading!")

        var list = doc.get("issues", [])
        for (var i = 0; i < list.length; i++) {
            var issue = issueComponent.createObject(mainView, {info: list[i].info})
            issue.fromJSON(list[i])
            issues.append({"modelData": issue})
        }

        var lastRefreshed = doc.get("lastRefreshed", "")

        var handler = function(response) {
            //print(response)
            var json = JSON.parse(response)
            print("LENGTH:", json.length)
            for (var i = 0; i < json.length; i++) {
                var found = false
                for (var j = 0; j < issues.count; j++) {
                    print(issues.get(j).modelData.number + " === " + json[i].number)
                    if (issues.get(j).modelData.number === json[i].number) {
                        issues.get(j).modelData.info = json[i]
                        found = true
                        break
                    }
                }

                if (!found) {
                    var issue = issueComponent.createObject(mainView, {info: json[i]})
                    issues.append({"modelData": issue})
                }
            }
        }

        github.getIssues("iBeliever/project-dashboard", "open", lastRefreshed, handler)
        github.getIssues("iBeliever/project-dashboard", "closed", lastRefreshed, handler)

        doc.set("lastRefreshed", new Date().toJSON())
    }

    Component {
        id: issueComponent

        Issue {

        }
    }
}
