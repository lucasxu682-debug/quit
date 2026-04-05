/**
 * Email Summary Script v2
 * Reads forwarded school emails from Gmail and generates a summary with analysis
 * 
 * Features:
 * - Filters out calendar@hkbu.edu.hk (daily "today" emails)
 * - Categorizes all emails
 * - Identifies important emails with brief analysis
 */

const Imap = require('imap');
const https = require('https');

// Gmail credentials
const config = {
  user: 'lucasxu682@gmail.com',
  password: 'bybx nwvt mkei qhul',
  host: 'imap.gmail.com',
  port: 993,
  tls: true,
  tlsOptions: { rejectUnauthorized: false }
};

// Discord webhook URL
const DISCORD_WEBHOOK_URL = 'https://discord.com/api/webhooks/1489244726837383209/2O-piK7xoIJbnq30k4nGQgMsjFhRXMZ7QML4zC0uKpmL9ZHz-74T9seFFxUGwajCLacK';

// Email to filter out (daily "today" emails - not useful)
const BLOCKED_SENDER = 'calendar@hkbu.edu.hk';

// Important keywords for categorization
const IMPORTANT_KEYWORDS = ['deadline', 'exam', 'assignment', 'due', 'grade', '成绩', '考试', '截止', '作业', '重要', 'urgent', 'final', '评分'];
const COURSE_KEYWORDS = ['HDDS', 'HDGS', 'timetable', 'tutorial', 'lecture', 'seminar', '课程', '课表'];
const ADMIN_KEYWORDS = ['registration', 'enrollment', 'fee', '学费', '注册', '行政', 'admin'];
const SYSTEM_KEYWORDS = ['noreply', 'no-reply', 'automated', '系统', '自动'];

function categorizeEmail(subject) {
  const lowerSubject = subject.toLowerCase();
  
  // Check if important
  const isImportant = IMPORTANT_KEYWORDS.some(kw => lowerSubject.includes(kw));
  
  // Determine category
  let category = '📌 其他';
  if (ADMIN_KEYWORDS.some(kw => lowerSubject.includes(kw))) {
    category = '🏛️ 行政事务';
  } else if (COURSE_KEYWORDS.some(kw => lowerSubject.includes(kw))) {
    category = '📚 课程相关';
  } else if (lowerSubject.includes('exam') || lowerSubject.includes('考试')) {
    category = '📝 考试相关';
  } else if (lowerSubject.includes('schedule') || lowerSubject.includes('时间表')) {
    category = '📅 日程安排';
  } else if (SYSTEM_KEYWORDS.some(kw => lowerSubject.includes(kw))) {
    category = '🤖 系统通知';
  }
  
  return { isImportant, category };
}

function analyzeEmail(subject) {
  const lowerSubject = subject.toLowerCase();
  
  // Generate brief analysis based on content
  if (lowerSubject.includes('exam') || lowerSubject.includes('考试') || lowerSubject.includes('timetable')) {
    return '📅 考试安排已发布，建议尽快查看考试时间和地点，合理安排复习计划';
  }
  if (lowerSubject.includes('deadline') || lowerSubject.includes('due') || lowerSubject.includes('截止')) {
    return '⏰ 有截止日期的任务，注意把握提交时间，避免逾期扣分';
  }
  if (lowerSubject.includes('assignment') || lowerSubject.includes('作业') || lowerSubject.includes('essay')) {
    return '📋 作业相关通知，检查作业要求和截止日期';
  }
  if (lowerSubject.includes('grade') || lowerSubject.includes('成绩') || lowerSubject.includes('result')) {
    return '📊 成绩相关通知，可能涉及评分或成绩公布';
  }
  if (lowerSubject.includes('registration') || lowerSubject.includes('enrollment') || lowerSubject.includes('注册')) {
    return '🎓 课程注册相关，注意注册截止日期和操作流程';
  }
  if (lowerSubject.includes('tutorial') || lowerSubject.includes('lecture') || lowerSubject.includes('课')) {
    return '📖 课程相关通知，查看是否有课程变动或新增内容';
  }
  if (lowerSubject.includes('fee') || lowerSubject.includes('学费') || lowerSubject.includes('payment')) {
    return '💰 费用相关，确认费用金额和缴纳截止日期';
  }
  
  return '💡 查看邮件详情获取更多信息';
}

function decodeSubject(subject) {
  const encodedMatch = subject.match(/\=\?UTF-8\?B\?(.+?)\?\=/);
  if (encodedMatch) {
    try {
      return Buffer.from(encodedMatch[1], 'base64').toString('utf8');
    } catch (e) {
      return subject;
    }
  }
  
  // Also handle quoted-printable
  const qpMatch = subject.match(/\=\?(.+?)\?Q\?(.+?)\?\=/);
  if (qpMatch) {
    try {
      const charset = qpMatch[1];
      const encoded = qpMatch[2].replace(/=([A-Fa-f0-9]{2})/g, (_, hex) => 
        String.fromCharCode(parseInt(hex, 16))
      );
      return encoded;
    } catch (e) {
      return subject;
    }
  }
  
  return subject;
}

async function readEmails() {
  return new Promise((resolve, reject) => {
    const imap = new Imap(config);
    
    imap.once('ready', () => {
      imap.openBox('INBOX', true, (err, box) => {
        if (err) {
          reject(err);
          imap.end();
          return;
        }
        
        // Get emails from last 3 days
        const since = new Date();
        since.setDate(since.getDate() - 3);
        
        imap.search([['SINCE', since]], (err, results) => {
          if (err || !results || results.length === 0) {
            resolve({ emails: [], total: 0 });
            imap.end();
            return;
          }
          
          fetchEmailDetails(results.reverse().slice(0, 30)).then(emails => {
            resolve({ emails, total: emails.length });
            imap.end();
          });
        });
      });
    });
    
    imap.once('error', err => reject(err));
    imap.connect();
  });
}

function fetchEmailDetails(messageIds) {
  return new Promise((resolve, reject) => {
    const imap = new Imap(config);
    const emails = [];
    
    imap.once('ready', () => {
      imap.openBox('INBOX', true, (err, box) => {
        if (err) {
          reject(err);
          imap.end();
          return;
        }
        
        const fetch = imap.fetch(messageIds, {
          bodies: 'HEADER.FIELDS (FROM SUBJECT DATE)',
          struct: true
        });
        
        fetch.on('message', msg => {
          let header = '';
          msg.on('body', stream => {
            stream.on('data', chunk => { header += chunk.toString('utf8'); });
            stream.once('end', () => {
              const lines = header.split('\r\n');
              const email = { from: '', subject: '', date: '', fromRaw: '' };
              
              for (const line of lines) {
                if (line.startsWith('From:')) {
                  email.fromRaw = line.replace('From:', '').trim();
                  // Extract email address
                  const emailMatch = line.match(/<(.+)>/);
                  email.from = emailMatch ? emailMatch[1] : line.replace('From:', '').trim();
                }
                if (line.startsWith('Subject:')) email.subject = line.replace('Subject:', '').trim();
                if (line.startsWith('Date:')) email.date = line.replace('Date:', '').trim();
              }
              
              email.subject = decodeSubject(email.subject);
              
              // Filter out blocked sender
              if (email.from === BLOCKED_SENDER) {
                return;
              }
              
              // Add categorization
              const { isImportant, category } = categorizeEmail(email.subject);
              email.isImportant = isImportant;
              email.category = category;
              email.analysis = analyzeEmail(email.subject);
              
              emails.push(email);
            });
          });
        });
        
        fetch.once('error', err => {
          resolve(emails);
        });
        
        fetch.once('end', () => {
          resolve(emails);
          imap.end();
        });
      });
    });
    
    imap.once('error', err => reject(err));
    imap.connect();
  });
}

function generateSummary(data) {
  const { emails, total } = data;
  const date = new Date().toLocaleDateString('zh-CN', { 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  });
  
  let summary = `# 📧 邮件摘要 (${date})\n\n`;
  
  if (emails.length === 0) {
    summary += `📭 过去 3 天没有收到学校邮件\n\n`;
  } else {
    summary += `📬 共收到 **${emails.length}** 封学校邮件\n\n`;
    
    // Group by category
    const grouped = {};
    for (const email of emails) {
      if (!grouped[email.category]) {
        grouped[email.category] = [];
      }
      grouped[email.category].push(email);
    }
    
    // Show important emails first
    const importantEmails = emails.filter(e => e.isImportant);
    if (importantEmails.length > 0) {
      summary += `## ⭐ 重要邮件\n\n`;
      for (const email of importantEmails) {
        summary += `### ${email.subject}\n`;
        summary += `📅 ${new Date(email.date).toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' })} | ${email.category}\n\n`;
        summary += `💬 **分析**: ${email.analysis}\n\n`;
        summary += `---\n\n`;
      }
    }
    
    // Show all emails by category
    summary += `## 📋 全部邮件\n\n`;
    for (const [category, categoryEmails] of Object.entries(grouped)) {
      summary += `### ${category}\n`;
      for (const email of categoryEmails) {
        const shortDate = new Date(email.date).toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' });
        summary += `- **${shortDate}** ${email.subject}${email.isImportant ? ' ⭐' : ''}\n`;
      }
      summary += `\n`;
    }
  }
  
  summary += `---\n_由 OpenClaw 自动生成_`;
  
  return summary;
}

async function sendToDiscord(message) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify({
      content: message,
      username: 'OpenClaw Email Summary'
    });
    
    const url = new URL(DISCORD_WEBHOOK_URL);
    const options = {
      hostname: url.hostname,
      path: url.pathname + url.search,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    };
    
    const req = https.request(options, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve();
        } else {
          reject(new Error(`Discord API error: ${res.statusCode}`));
        }
      });
    });
    
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

async function main() {
  try {
    console.log('📧 Reading school emails from Gmail...');
    const data = await readEmails();
    
    console.log(`Found ${data.emails.length} emails`);
    
    const summary = generateSummary(data);
    
    console.log('\n' + summary + '\n');
    
    console.log('Sending to Discord...');
    await sendToDiscord(summary);
    console.log('✅ Done!');
    
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  }
}

main();
