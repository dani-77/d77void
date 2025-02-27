/* === This file is part of Calamares - <https://calamares.io> ===
 *
 *   SPDX-FileCopyrightText: 2015 Teo Mrnjavac <teo@kde.org>
 *   SPDX-FileCopyrightText: 2018 Adriaan de Groot <groot@kde.org>
 *   SPDX-License-Identifier: GPL-3.0-or-later
 *
 *   Calamares is Free Software: see the License-Identifier above.
 *
 */

import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    function nextSlide() {
        console.log("QML Component (default slideshow) Next slide");
        presentation.goToNextSlide();
    }

    Timer {
        id: advanceTimer
        interval: 7500
        running: true
        repeat: true
        onTriggered: nextSlide()
    }
	
    Slide {

        Image {
            id: squid
            source: "1squid.png"
            width: 200; height: 200
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
        }
        Text {
            anchors.horizontalCenter: squid.horizontalCenter
            anchors.top: background.bottom
            text: "This is a simple Calamares installer for d77void.<br/>"+
                  "Void distribution don't have it by default and because of some complaints about the default install method, this was created."
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
        }
    }

    Slide {

        Image {
            id: background
            source: "2background1.png"
            width: 640 
	    height: 360
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
        }
        Text {
            anchors.horizontalCenter: background.horizontalCenter
            anchors.top: background.bottom
            text: "One of the few original backgrounds created for d77."
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
        }
    }

    Slide {

        Image {
            id: octo
            source: "4octo.png"
            width: 640
	    height: 360
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
        }

        Text {
            anchors.horizontalCenter: desktop.horizontalCenter
            anchors.top: background.bottom
            text: "   "
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
        }
    }

    Slide {

        Image {
            id: desktop
            source: "3desktop.png"
            width: 640
	    height: 360
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
        }
       Text {
           anchors.horizontalCenter: desktop.horizontalCenter
           anchors.top: background.bottom
           text: "   "
           wrapMode: Text.WordWrap
           width: presentation.width
           horizontalAlignment: Text.Center
       }
    }
          
    // When this slideshow is loaded as a V1 slideshow, only
    // activatedInCalamares is set, which starts the timer (see above).
    //
    // In V2, also the onActivate() and onLeave() methods are called.
    // These example functions log a message (and re-start the slides
    // from the first).
    function onActivate() {
        console.log("QML Component (default slideshow) activated");
        presentation.currentSlide = 0;
    }

    function onLeave() {
        console.log("QML Component (default slideshow) deactivated");
    }

}
