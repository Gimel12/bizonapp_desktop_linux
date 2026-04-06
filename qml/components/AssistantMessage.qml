import QtQuick
import QtQuick.Layouts

Rectangle {
    id: assistantMsg
    width: parent ? parent.width : 400
    implicitHeight: col.implicitHeight + 24
    color: "transparent"

    property string messageText: ""

    // ── Line-by-line markdown → HTML converter ──────────────────────────
    // Processes each line individually and groups list items together
    // to prevent Qt's Text element from adding excessive spacing.
    function mdToRich(text) {
        if (!text) return "";

        // ── Read theme colors once for use in HTML ─────────────────────
        var T = {
            text: Theme.htmlTextColor, bold: Theme.htmlBoldColor,
            head: Theme.htmlHeadColor, bullet: Theme.htmlBulletColor,
            codeBg: Theme.htmlCodeBg, codeColor: Theme.htmlCodeColor,
            codeBorder: Theme.htmlCodeBorder,
            icBg: Theme.htmlInlineCodeBg, icFg: Theme.htmlInlineCodeFg,
            thBg: Theme.htmlTableHeaderBg, trAlt: Theme.htmlTableRowAlt,
            trBg: Theme.htmlTableRowBg, tBorder: Theme.htmlTableBorder,
            thText: Theme.htmlTableHeadText, tdText: Theme.htmlTableCellText,
            hr: Theme.htmlHrColor, num: Theme.htmlNumColor
        };

        // ── Pre-process: extract code blocks before line processing ─────
        var codeBlocks = [];
        var s = text.replace(/```(\w*)\n([\s\S]*?)```/g, function(match, lang, code) {
            var idx = codeBlocks.length;
            codeBlocks.push(
                '<table cellpadding="0" cellspacing="0" width="100%"><tr><td style="background:' + T.codeBg + '; ' +
                'padding:10px 14px; font-family:monospace; font-size:12px; color:' + T.codeColor + '; ' +
                'border:1px solid ' + T.codeBorder + '; white-space:pre-wrap;">' + code.trim() + '</td></tr></table>'
            );
            return '\x00CODEBLOCK_' + idx + '\x00';
        });

        // ── Pre-process: extract markdown tables ────────────────────────
        var tableBlocks = [];
        s = s.replace(/((?:^\|.+\|$\n?)+)/gm, function(tableBlock) {
            var rows = tableBlock.trim().split('\n');
            if (rows.length < 2) return tableBlock;

            var html = '<table cellpadding="0" cellspacing="0" width="100%">';

            for (var i = 0; i < rows.length; i++) {
                var row = rows[i].trim();
                if (!row.startsWith('|')) continue;
                if (/^\|[\s\-:]+\|/.test(row) && row.indexOf('---') !== -1) continue;

                var cells = row.split('|').filter(function(c, idx, arr) {
                    return idx > 0 && idx < arr.length - 1;
                });

                var isHeader = (i === 0);
                var tag = isHeader ? 'th' : 'td';
                var bg = isHeader ? T.thBg : (i % 2 === 0 ? T.trAlt : T.trBg);
                var fw = isHeader ? 'font-weight:600;' : '';
                var tc = isHeader ? ('color:' + T.thText + ';') : ('color:' + T.tdText + ';');

                html += '<tr>';
                for (var j = 0; j < cells.length; j++) {
                    html += '<' + tag + ' style="padding:6px 12px; border-bottom:1px solid ' + T.tBorder + '; ' +
                            'background:' + bg + '; ' + fw + tc + '">' +
                            inlineFormat(cells[j].trim(), T) + '</' + tag + '>';
                }
                html += '</tr>';
            }
            html += '</table>';
            var tidx = tableBlocks.length;
            tableBlocks.push(html);
            return '\x00TABLE_' + tidx + '\x00';
        });

        // ── Process line by line ────────────────────────────────────────
        var lines = s.split('\n');
        var out = [];
        var i = 0;

        while (i < lines.length) {
            var line = lines[i];
            var trimmed = line.trim();

            // Skip empty lines
            if (trimmed === '') { i++; continue; }

            // Restore code blocks
            if (trimmed.indexOf('\x00CODEBLOCK_') !== -1) {
                var cbMatch = trimmed.match(/\x00CODEBLOCK_(\d+)\x00/);
                if (cbMatch) out.push(codeBlocks[parseInt(cbMatch[1])]);
                i++; continue;
            }

            // Restore tables
            if (trimmed.indexOf('\x00TABLE_') !== -1) {
                var tbMatch = trimmed.match(/\x00TABLE_(\d+)\x00/);
                if (tbMatch) out.push(tableBlocks[parseInt(tbMatch[1])]);
                i++; continue;
            }

            // Horizontal rule
            if (/^---+$/.test(trimmed)) {
                out.push('<table width="100%"><tr><td style="border-bottom:1px solid ' + T.hr + '; padding:4px 0;"></td></tr></table>');
                i++; continue;
            }

            // Headers
            var hMatch = trimmed.match(/^(#{1,4})\s+(.+)$/);
            if (hMatch) {
                var level = hMatch[1].length;
                var sizes = [16, 15, 14, 13];
                var sz = sizes[level - 1] || 13;
                out.push('<p style="margin-top:8px; margin-bottom:2px; font-size:' + sz +
                         'px; font-weight:700; color:' + T.head + ';">' + inlineFormat(hMatch[2], T) + '</p>');
                i++; continue;
            }

            // Bullet list — collect consecutive bullet lines
            if (/^[\-\*]\s+/.test(trimmed)) {
                var bullets = [];
                while (i < lines.length) {
                    var bl = lines[i].trim();
                    var bm = bl.match(/^[\-\*]\s+(.+)$/);
                    if (bm) {
                        bullets.push(bm[1]);
                        i++;
                    } else if (bl === '') {
                        if (i + 1 < lines.length && /^[\-\*]\s+/.test(lines[i+1].trim())) {
                            i++; continue;
                        }
                        break;
                    } else {
                        break;
                    }
                }
                var bhtml = '<table cellpadding="0" cellspacing="0" width="100%">';
                for (var bi = 0; bi < bullets.length; bi++) {
                    bhtml += '<tr><td width="16" valign="top" style="color:' + T.bullet + '; padding:2px 0; font-size:13px;">\u2022</td>' +
                             '<td style="padding:2px 4px; color:' + T.text + '; font-size:13px;">' +
                             inlineFormat(bullets[bi], T) + '</td></tr>';
                }
                bhtml += '</table>';
                out.push(bhtml);
                continue;
            }

            // Numbered list — collect consecutive numbered lines
            if (/^\d+\.\s+/.test(trimmed)) {
                var nums = [];
                while (i < lines.length) {
                    var nl = lines[i].trim();
                    var nm = nl.match(/^(\d+)\.\s+(.+)$/);
                    if (nm) {
                        nums.push({ n: nm[1], text: nm[2] });
                        i++;
                    } else if (nl === '') {
                        if (i + 1 < lines.length && /^\d+\.\s+/.test(lines[i+1].trim())) {
                            i++; continue;
                        }
                        break;
                    } else {
                        break;
                    }
                }
                var nhtml = '<table cellpadding="0" cellspacing="0" width="100%">';
                for (var ni = 0; ni < nums.length; ni++) {
                    nhtml += '<tr><td width="22" valign="top" style="color:' + T.num + '; padding:2px 0; font-size:13px; font-weight:600;">' +
                             nums[ni].n + '.</td>' +
                             '<td style="padding:2px 4px; color:' + T.text + '; font-size:13px;">' +
                             inlineFormat(nums[ni].text, T) + '</td></tr>';
                }
                nhtml += '</table>';
                out.push(nhtml);
                continue;
            }

            // Plain paragraph
            out.push('<p style="margin-top:2px; margin-bottom:2px; color:' + T.text + '; font-size:13px;">' +
                     inlineFormat(trimmed, T) + '</p>');
            i++;
        }

        return out.join('');
    }

    // ── Inline formatting (bold, italic, code, links) ───────────────────
    function inlineFormat(text, T) {
        var s = text;
        // Inline code
        s = s.replace(/`([^`]+)`/g,
            '<span style="background:' + T.icBg + '; padding:1px 5px; font-family:monospace; ' +
            'font-size:12px; color:' + T.icFg + ';">$1</span>');
        // Bold
        s = s.replace(/\*\*(.+?)\*\*/g, '<b style="color:' + T.bold + ';">$1</b>');
        // Italic
        s = s.replace(/(?<!\*)\*([^*]+)\*(?!\*)/g, '<i>$1</i>');
        return s;
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 0

        Text {
            Layout.fillWidth: true
            textFormat: Text.RichText
            text: mdToRich(assistantMsg.messageText)
            wrapMode: Text.Wrap
            onLinkActivated: function(link) { Qt.openUrlExternally(link) }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.divider
    }
}
