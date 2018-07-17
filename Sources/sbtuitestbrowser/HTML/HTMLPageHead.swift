//
//  TemplateHead.swift
//  sbtuitestbrowser
//
//  Created by Tomas Camin on 05/07/2018.
//

extension HTMLPage {
    static func head(title: String) -> String {
        
        return """
        <head>
        <meta charset="utf-8">
        <link rel="stylesheet" href="https://www.w3schools.com/w3css/4/w3.css">
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>

        <title>UI Test Browser - testReportAd_withReason_andEmptyDescription</title>
        
        <style type="text/css">
        
        html, body {
        margin: 0;
        padding: 0;
        font-size: 10pt;
        font-family: "SF Pro Display", "SF Pro Icons", "Helvetica Neue", "Helvetica", "Arial";
        height: 100%;
        color: #000;
        background-color: #fff;
        }
        
        #header {
        z-index: 999;
        position: fixed;
        top: 0px;
        left: 0px;
        background-color: #ff4440;
        color: #fff;
        width: 100%;
        padding: 10px;
        border-bottom: 0.5pt solid #ddd;
        }
        
        #fixed_screenshot {
        position: fixed;
        right: 0px;
        height: 100%;
        }
        
        div.centered {
        justify-content: center;
        display: flex;
        align-items: center;
        }
        
        div.separator {
        background-color: #f8f8f8;
        border-bottom: 0.5pt solid #ddd;
        padding-top: 14pt;
        padding-bottom: 3pt;
        padding-left: 10pt;
        }
        
        div.item_title {
        border-top: 0.5pt solid #ddd;
        border-bottom: 0.5pt solid #ddd;
        background-color: #f8f8f8;
        height: 30px;
        padding-left: 20pt;
        display: flex;
        align-items: center;
        font-weight: bold;
        }
        
        div.item {
        border-bottom: 0.5pt solid #eeeeeef0;
        padding-top: 0pt;
        padding-bottom: 0pt;
        padding-left: 5pt;
        }
        
        div.step {
        padding-left: 10pt;
        padding-top: 1pt;
        padding-bottom: 1pt;
        }
        
        div.code {
        padding: 10pt;
        font-family: "SF Mono", "Menlo", "Courier";
        }
        
        div.item.failure {
        background-color: #ff000008;
        }
        
        div.item a { text-decoration: none; color: #000; }
        div.item a:hover { text-decoration: underline; color: #444; text-shadow: 0px 0px 0px #fff; }
        
        .bold {
        font-weight: bold;
        }
        
        .hidden {
        visibility: hidden;
        }
        
        .red {
        color: #c82836 !important;
        }
        
        .red_fill {
        background-color: #c82836 !important;
        }
        
        .uncovered_line {
        color: #530000 !important;
        }
        
        .green {
        color: #30a64a !important;
        }
        
        .gray {
        color: #5a5a5a !important;
        }
        
        .light_gray {
        color: #b9b9b9 !important;
        }
        
        .green {
        color: rgb(60, 200, 90) !important;
        }
        
        svg {
        fill: currentColor;
        }
        
        .button_selected {
        background-color:#fff;
        -moz-border-radius: 5px;
        -webkit-border-radius: 5px;
        border-radius: 5px;
        display: inline-block;
        cursor: pointer;
        color: #ff4440;
        padding: 5px 10px;
        text-decoration: none;
        font-size: 100%;
        margin-left: 2px;
        margin-right: 2px;
        margin-top: 5px;
        margin-bottom: 5px;
        }
        
        .button_selected:active {
        color: #fff;
        background-color: #ffffff60;
        position: relative;
        }
        
        .button_deselected {
        -moz-border-radius: 5px;
        -webkit-border-radius: 5px;
        border-radius: 5px;
        display: inline-block;
        cursor: pointer;
        color: #fff;
        padding: 5px 10px;
        text-decoration: none;
        font-size: 100%;
        margin-right: 5px;
        margin-top: 5px;
        margin-bottom: 5px;
        }
        
        .button_deselected:active {
        background-color: #1f69ee;
        position: relative;
        }
        
        .button_deselected:hover {
        background-color: #ffffff60;
        text-shadow: 0px -1px 1px #d90b0f50;
        color: #fff;
        position: relative;
        }
        
        .flip_horizontal {
        transform: rotate(180deg);
        transform-origin: 50% 50%;
        }
        
        .rotate_90deg {
        transform: rotate(90deg);
        transform-origin: 50% 50%;
        }
        
        .rotate_270deg {
        transform: rotate(270deg);
        transform-origin: 50% 50%;
        }
        
        .svg-icon {
        display: inline-flex;
        align-self: center;
        }
        .svg-icon svg {
        height:1em;
        width:1em;
        }
        .svg-icon.svg-baseline svg {
        top: .2em;
        position: relative;
        }
        
        </style>
        </head>
        """
    }
}
