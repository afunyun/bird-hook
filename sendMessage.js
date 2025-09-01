function postDiscord(postMsg) {
  const props = PropertiesService.getScriptProperties();
  const webhooks = props.getProperty("WEBHOOKS"); // get value from project properties
  const token = props.getProperty("TOKEN");
  const channel = 'jobs' // channel name
  const parse = 'full';
  const method = 'post';

  const payload = {
    'token': token,
    'channel': channel,
    'content': postMsg,
    'parse': parse,
  };

  const params = {
    'method': method,
    'payload': payload,
    'muteHttpExceptions': true,
  };
  response = UrlFetchApp.fetch(webhooks, params);
}

function sendMailsToDiscord() {
  const searchQuery = 'label:mailinglist@lists.example.com and subject:job';
  const dt = new Date();
  const checkSpan = 30;
  dt.setMinutes(dt.getMinutes() - checkSpan);

  const threads = GmailApp.search(searchQuery);
  const msgs = GmailApp.getMessagesForThreads(threads);
  for(let i =0; i<msgs.length; i++) {
    const lastMsgDt = threads[i].getLastMessageDate();

    if(lastMsgDt.getTime() < dt.getTime()) {
      break;
    }

    for(let j =0; j<msgs[i].length; j++) {
      const msgDate = msgs[i][j].getDate();
      // const msgBody = msgs[i][j].getBody(); // html
      const msgBody = msgs[i][j].getPlainBody();
      const subject = msgs[i][j].getSubject()
      const postMsg = "From mailing list" + "\n" +
          Utilities.formatDate(msgDate, 'America/New_York', 'MM/DD/yyyy hh:mm:ss') + "\n" +
              "Title:" + subject + "\n" +
              "[hr]" +
               msgBody;
      console.log(`chars: ${postMsg.length}`);
      // The limit is 2000 characters
      if(postMsg.length > 2000) {
        const stopPos = 1900; //
        const msg =  "`This message is more than 2000 chars so I cannot post the entire message. Sorry.`";
        postMsg = postMsg.substring(0, stopPos) + "\n" + msg
      }
      console.log(postMsg);
      console.log('===================================');
      console.log(`chars: ${postMsg.length}`);
      console.log('===================================');
      postDiscord(postMsg);
    }
  }
}
