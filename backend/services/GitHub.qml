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
import "../../ubuntu-ui-extras/httplib.js" as Http
import "../../ubuntu-ui-extras"
import ".."

Service {
    id: root

    name: "github"
    type: "GitHub"
    title: i18n.tr("GitHub")
    authenticationStatus: oauth === "" ? "" : i18n.tr("Logged in as %1").arg(user.login)
    disabledMessage: i18n.tr("Authenticate to GitHub in Settings")

    enabled: oauth !== ""

    property string oauth:settings.get("githubToken", "")
    property string github: "https://api.github.com"
    property var user: settings.get("githubUser", "")
    property var repos: settings.get("githubRepos", [])

    function isEnabled(project) {
        if (enabled) {
            return ""
        } else {
            return disabledMessage
        }
    }

    onOauthChanged: {
        if (oauth !== "") {
            get("/user", userLoaded)
            get("/user/repos", function(status, response) {
                if (status !== 304)
                    settings.set("githubRepos", JSON.parse(response))
            })
        } else {
            settings.set("githubUser", undefined)
        }
    }

    function userLoaded(status, response) {
        var json = JSON.parse(response)
        settings.set("githubUser", json)
    }

    function get(request, callback, options) {
        //print("OAuth", oauth)
        if (oauth === "")
            return undefined
        if (options === undefined)
            options = []
        if (request && request.indexOf(github) !== 0)
            request = github + request
        queue.httpGet(request,["access_token=" + oauth].concat(options), {"Accept":"application/vnd.github.v3+json"}, callback, undefined)
    }

    function post(request, options, body, message) {
        //print("OAuth", oauth)
        if (oauth === "")
            return undefined
        if (options === undefined)
            options = []
        if (request && request.indexOf(github) !== 0)
            request = github + request
        queue.http("POST", request, ["access_token=" + oauth].concat(options), {"Accept":"application/vnd.github.v3+json"}, body, message)
    }

    function put(request, options, body, message) {
        //print("OAuth", oauth)
        if (oauth === "")
            return undefined
        if (options === undefined)
            options = []
        if (request && request.indexOf(github) !== 0)
            request = github + request
        queue.http("PUT", request, ["access_token=" + oauth].concat(options), {"Accept":"application/vnd.github.v3+json"}, body, message)
    }

    function getEvents(repo, callback) {
        get("/repos/" + repo + "/events", callback)
    }

    function getIssues(repo, state, since,callback) {
        return get("/repos/" + repo + "/issues", callback, ["state=" + state, "since=" + since])
    }

    function editIssue(repo, number, issue) {
        post("/repos/" + repo + "/issues/" + number, undefined, JSON.stringify(issue), i18n.tr("Update issue <b>%1</b>").arg(number))
    }

    function newIssue(repo, title, description) {
        return post("/repos/" + repo + "/issues", undefined, JSON.stringify({ "title": title, "body": description }), i18n.tr("Create issue <b>%1</b>").arg(title))
    }

    function newPullRequest(repo, title, description, branch) {
        return post("/repos/" + repo + "/pulls", undefined, JSON.stringify({ "title": title, "body": description, "head": branch, "base": "master" }), i18n.tr("Create pull request <b>%1</b>").arg(title))
    }

    function mergePullRequest(repo, number, message) {
        put("/repos/" + repo + "/pulls/" + number + "/merge", undefined, JSON.stringify({ "commit_message": message }), i18n.tr("Merge pull request <b>%1</b>").arg(number))
    }

    function getPullRequests(repo, state, since, callback) {
        return get("/repos/" + repo + "/pulls", callback, ["state=" + state, "since=" + since])
    }

    function getPullRequest(repo, number, callback) {
        return get("/repos/" + repo + "/pulls/" + number, callback)
    }

    function getAssignees(repo, callback) {
        return get("/repos/" + repo + "/assignees", callback)
    }

    function getMilestones(repo, callback) {
        return get("/repos/" + repo + "/milestones", callback)
    }

    function getLabels(repo, callback) {
        return get("/repos/" + repo + "/labels", callback)
    }

    function getBranches(repo, callback) {
        return get("/repos/" + repo + "/branches", callback)
    }

    function getRepository(repo, callback) {
        return get("/repos/" + repo, callback)
    }

    function getIssueComments(repo, issue, callback) {
        return get('/repos/' + repo + '/issues/' + issue.number + '/comments', callback)
    }

    function getPullCommits(repo, pull, callback) {
        return get('/repos/' + repo + '/pulls/' + pull.number + '/commits', callback)
    }

    function getIssueEvents(repo, issue, callback) {
        return get('/repos/' + repo + '/issues/' + issue.number + '/events', callback)
    }

    function newIssueComment(repo, issue, comment) {
        post("/repos/" + repo + "/issues/" + issue.number + "/comments", undefined, JSON.stringify({body: comment}), i18n.tr("Comment on issue <b>%1</b>").arg(issue.number))
    }

    function authenticate() {
        pageStack.push(Qt.resolvedUrl("OAuthPage.qml"))
    }

    function revoke() {
        settings.set("githubToken", "")
    }

    function status(value) {
        return i18n.tr("Connected to %1").arg(value)
    }

    Component {
        id: accessRevokedDialog

        Dialog {

            title: i18n.tr("GitHub Access Revoked")
            text: i18n.tr("You will no longer be able to access any projects on GitHub. Go to Settings to re-enable GitHub integration.")

            Button {
                text: i18n.tr("Ok")
                onTriggered: {
                    PopupUtils.close(accessRevokedDialog)
                }
            }

            Button {
                text: i18n.tr("Open Settings")
                onTriggered: {
                    PopupUtils.close(accessRevokedDialog)
                    pageStack.push(Qt.resolvedUrl("ui/SettingsPage.qml"))
                }
            }
        }
    }
}
