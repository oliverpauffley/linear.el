;;; linear.el --- Linear kanban board management -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023 Oliver Pauffley
;;
;; Author: Oliver Pauffley <mrpauffley@gmail.com>
;; Maintainer: Oliver Pauffley <mrpauffley@gmail.com>
;; Created: December 13, 2023
;; Modified: December 13, 2023
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/oliverpauffley/linear
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:

;; Functions and UI for talking to the linear gql api to search, update, add and delete tickets in linear
;;
;;; Code:
(require 'graphql)
(require 'url)
(require 'url-dav)
(require 'emacs "25.1")
(require 'subr-x)

;; TODO link queries together to go from blank slate to user issues (will need to grab the data from reponses)
;; TODO handle emacs requirements (subr-x etc)
;; TODO Transient UI?
;; TODO Link to org mode todos?


(defconst linear-url "https://api.linear.app/graphql"
  "The linear graphql url.")

(defvar linear-auth-token ""
  "Linear authentication token.")

;; hardcoded initial query to get the logged in users ID.
(defconst linear--user-query (graphql-query ((viewer id name email))))
;; hardcoded initial query to get the logged in users team ID.
(defconst linear--team-query (graphql-query ((teams (nodes id name)))))

(defvar linear--user-id)
(defvar linear--team-id)

(defun linear--build-team-tickets-query (team-id)
  "Find all tickets for the given team ID."
  (graphql-encode
   `(query
     (team :arguments
           ((id . ,team-id))
           id name
           (issues
            (nodes id title description createdAt archivedAt
                   (assignee id name)))))))

(defun linear--build-user-tickets-query (user-id)
  "Find all tickets for the given team ID."
  (graphql-encode
   `(query
     (issues :arguments
             ((filter . ((assignee . ((id . (("eq" . ,user-id))))))))
             (nodes id title description createdAt archivedAt
                    (assignee id name))))))

(defun linear--build-ticket-query (ticket-id)
  "Find all tickets for the given team ID."
  (graphql-encode
   `(query
     (issue :arguments
            ((id . ,ticket-id))
            id title description))))


(defun linear--make-request (type object)
  (thread-last (graphql-encode object)
               (cons type)
               (list)
               (json-encode)
               (linear--graphql-request)))

(defun linear--graphql-request (query)
  "Make a linear graphql request. AUTH is the linear authentication token.
QUERY is a linear graphql query for data."
  (let ((url-request-method "POST")
        (url-request-extra-headers
         `(("Content-Type" . "application/json")
           ("Authorization" . ,linear-auth-token)))
        (url-request-data  query))
    (with-current-buffer (url-retrieve-synchronously linear-url)
      (goto-char url-http-end-of-headers)
      (json-read))))

;; DEBUG QUERIES
(linear--make-request "query" (linear--build-ticket-query "SFE-347"))
(linear--make-request "query" linear--user-query)
(linear--make-request "query" (linear--build-user-tickets-query "08a2fabd-3979-44fb-887e-bf7f4d4627b7"))

(provide 'linear)
;;; linear.el ends here
